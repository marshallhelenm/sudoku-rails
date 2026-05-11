##
# Puzzle represents a 9x9 Sudoku grid and provides methods for manipulating and querying the puzzle state.
#
# Attributes:
#   matrix        - Matrix of Cell objects representing the puzzle grid
#
# Methods:
#   initialize(values:, options:, source_matrix:) - Create a new puzzle matrix
#   duplicate                                    - Return a deep copy of the puzzle
#   reset_options                                - Reset all cell options
#   cell(i, j)                                   - Get the cell at (i, j)
#   row(ci), column(cj)                          - Get a row or column as a Group
#   block(ci, cj), block_from_cell(cell)         - Get a block (3x3 region)
#   groups, vectors, blocks                      - Get all logical groups
#   count_confirmed_values, count_blank_cells    - Count filled/empty cells
#   values_matrix, values_array                  - Get values as matrix/array
#   options_matrix, options_array                - Get options as matrix/array
#   siblings_of(cell)                            - Get all siblings of a cell

class Puzzle
    require "matrix"
    require "set"
    require "sqids"
    require_relative "sudoku"
    require_relative "cell"
    require_relative "group"
    require_relative "row"
    require_relative "column"
    require_relative "block"
    require_relative "sudoku_cache"
    @@sqids = Sqids.new(salt: "sudoku-puzzle", alphabet: "0123456789abcdef", min_length: 4)

    # Initialize a Puzzle with optional values, options, or a source matrix.
    # Raises ArgumentError if input types are invalid.
    def initialize(values: nil, options: nil, source_matrix: nil)
        validate_source_matrix(source_matrix)
        validate_values(values)
        validate_options(options)

        @matrix = Matrix.build(9) do |ci, cj|
            if source_matrix.present?
                source_cell = source_matrix.cell(ci, cj)
                value = source_cell.value
                cell_options = source_cell.options.dup
            elsif values.present?
                value = values[ci, cj]
                cell_options = options[ci, cj].dup if options.present?
            else
                value = 0
                cell_options = Set.new(1..9)
            end
            Cell.new(puzzle: self, value: value, ci: ci, cj: cj, options: cell_options)
        end

        @id = @@sqids.encode([ Time.now.to_i ])

        @collections_cache = SudokuCache.new({
            groups: { current: false, value: nil },
            blocks: { current: false, value: nil },
            rows: { current: false, value: nil },
            columns: { current: false, value: nil }
        })

        @cache = SudokuCache.new({
            blank_cells: { current: false, value: nil },
            values_matrix: { current: false, value: nil },
            options_matrix: { current: false, value: nil },
            values_array: { current: false, value: nil },
            options_array: { current: false, value: nil },
            groups_valid: { current: false, value: nil },
            confirmed_count: { current: false, value: nil },
            count_blank_cells: { current: false, value: nil }
        })
    end

    attr_reader :matrix, :id

    def inspect
        "#<Puzzle id=#{@id} confirmed_count=#{confirmed_count} blank_cells=#{count_blank_cells} values=#{values_array}>"
    end

    def confirmed_count
        @cache.cache_or_compute(:confirmed_count) { count_confirmed_values }
    end

    # -- Accessor methods for cells, rows, columns, blocks, and groups --

    # Get the cell at (i, j)
    def cell(i, j)
        @matrix[i, j]
    end

    # Return the matrix of cells
    def cells
        @matrix
    end

    # Get a row as a Group object
    def row(ci)
        rows[ci]
    end

    # Get a column as a Group object
    def column(cj)
        columns[cj]
    end

    def rows
        @collections_cache.cache_or_compute(:rows) { build_rows }
    end

    def columns
        @collections_cache.cache_or_compute(:columns) { build_columns }
    end

    # Get all row and column Group objects
    def vectors
        rows.values + columns.values
    end

    # Get the Block object for the given block indices
    def block(ci, cj)
        blocks[[ ci, cj ]]
    end

    # Get all Block objects in the puzzle
    def blocks
        @collections_cache.cache_or_compute(:blocks) { build_blocks }
    end

    def blocks_array
        blocks.values
    end

    # Get all logical groups (rows, columns, and blocks)
    def groups
        @collections_cache.cache_or_compute(:groups) { vectors + blocks.values }
    end

    # -- Methods for querying puzzle state --

    # Count the number of cells with a confirmed (nonzero) value
    def count_confirmed_values
        @matrix.count { |cell| !cell.empty? }
    end

    # Return the number of values remaining to be filled
    def values_remaining
        81 - confirmed_count
    end

    # Returns true if the puzzle is complete (all cells confirmed)
    def complete?
        confirmed_count == 81
    end

    def blank_cells
        @cache.cache_or_compute(:blank_cells) { @matrix.select { |cell| cell.empty? } }
    end

    # Count the number of blank (zero) cells
    def count_blank_cells
        @cache.cache_or_compute(:count_blank_cells) { blank_cells.size }
    end

    # Return a matrix of cell values
    def values_matrix
        @cache.cache_or_compute(:values_matrix) { @matrix.map { |cell| cell.value } }
    end

    # Return an array of cell values
    def values_array
        @cache.cache_or_compute(:values_array) { values_matrix.to_a }
    end

    # Return a matrix of cell options
    def options_matrix
        @cache.cache_or_compute(:options_matrix) { @matrix.map { |cell| cell.options } }
    end

    # Return an array of cell options
    def options_array
        @cache.cache_or_compute(:options_array) { options_matrix.to_a }
    end

    def json_friendly_options_array
        options_array.map do |row|
            row.map { |opts| opts.to_a }
        end
    end

    # Count the number of empty cells with no options
    def optionless_cell_count
        @matrix.count do |cell|
            cell.value == 0 && cell.options.length == 0
        end
    end

    # Update the confirmed count and return true if it changed
    def update_confirmed_count
        new_values_found = count_confirmed_values
        number_changed = new_values_found != @cache[:confirmed_count][:value]
        @cache[:confirmed_count][:value] = new_values_found
        @cache[:confirmed_count][:current] = true
        number_changed
    end

    # -- Methods for manipulating puzzle state --


    # Reset all cell options: filled cells get [], empty cells get full range
    def reset_options
        @matrix.each do |cell|
            if cell.value != 0
                cell.options = Set.new
            else
                cell.options = Set.new(1..9)
            end
        end
    end

    def evaluate_initial_options
        @matrix.each do |cell|
            cell.evaluate_options(true)
        end
    end

    # Returns true if all groups are valid
    def valid?
        @cache.cache_or_compute(:groups_valid) { groups.all?(&:valid?) }
    end

    # Returns true if the puzzle is valid and complete
    def complete_and_valid?
        valid? && complete?
    end

    def reevaluate_all_options
        @matrix.each do |cell|
            next unless cell.empty?
            cell.evaluate_options(true)
        end
    end

    # -- other helper methods --

    # Return a deep copy of the puzzle matrix
    def duplicate
        Puzzle.new(source_matrix: self)
    end

    def print_values
        puts ""
        rows.values.each do |row|
            row.cells.each do |cell|
                print cell.value == 0 ? "." : cell.value
                print " "
                if cell.cj == 2 || cell.cj == 5
                    print "| "
                end
                print "\n" if cell.cj == 8
            end
            if row.cells.first.ci == 2 || row.cells.first.ci == 5
                puts "------+-------+------"
            end
        end
        nil
    end

    def bust_info_cache
        @cache.bust_entire_cache
    end

    private

    # -- Validation methods for initializer inputs -

    def validate_source_matrix(source_matrix)
        return unless source_matrix
        unless source_matrix.is_a?(Puzzle)
            raise ArgumentError, "source_matrix must be a Puzzle instance"
        end
    end

    def validate_values(values)
        return unless values
        unless values.is_a?(Matrix) && values.all? { |v| v.is_a?(Integer) }
            raise ArgumentError, "values must be a Matrix of integers"
        end
    end

    def validate_options(options)
        return unless options
        unless options.is_a?(Matrix) && options.all? { |v| v.is_a?(Set) && v.all? { |i| i.is_a?(Integer) } }
            raise ArgumentError, "options must be a Matrix of sets of integers"
        end
    end

    # -- Helper methods for caching groups --

    # Helper methods to build rows, columns, blocks, and groups for caching
    def build_rows
      rows_hash = {}
      Sudoku::COORD_RANGE.each do |ci|
        rows_hash[ci] = Row.new(@matrix.row(ci).to_a)
      end
      rows_hash
    end

    # Build columns as Column objects and return a hash mapping column index to Column
    def build_columns
      columns_hash = {}
      Sudoku::COORD_RANGE.each do |cj|
        columns_hash[cj] = Column.new(@matrix.column(cj).to_a)
      end
      columns_hash
    end

    # Build blocks as Block objects and return a hash mapping block coordinates to Block
    def build_blocks
        blocks_hash = {}
        [  [ 0, 0 ], [ 0, 1 ], [ 0, 2 ],
           [ 1, 0 ], [ 1, 1 ], [ 1, 2 ],
           [ 2, 0 ], [ 2, 1 ], [ 2, 2 ] ].each do |coords|
            blocks_hash[coords] = Block.new(self, coords[0], coords[1])
        end
        blocks_hash
    end

    # Build all groups (rows, columns, blocks) and return as a set
    def build_groups
        groups_set = Set.new
        rows.each { |row| groups_set.add(row) }
        columns.each { |col| groups_set.add(col) }
        blocks.each { |block| groups_set.add(block) }
        groups_set
    end
end
