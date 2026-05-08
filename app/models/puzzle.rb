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
    require_relative "sudoku"
    require_relative "cell"
    require_relative "group"
    require_relative "block"

    # Initialize a Puzzle with optional values, options, or a source matrix.
    # Raises ArgumentError if input types are invalid.
    def initialize(values: nil, options: nil, source_matrix: nil)
        validate_source_matrix(source_matrix)
        validate_values(values)
        validate_options(options)

        @matrix = Matrix.build(9) { |ci, cj| Cell.new(value: 0, ci: ci, cj: cj) }

        if source_matrix.present?
            # Copy values and options from the source matrix
            @matrix.each_with_index do |cell, ci, cj|
                source_cell = source_matrix.cell(ci, cj)
                cell.value = source_cell.value
                cell.options = source_cell.options.dup
            end
        elsif values.present?
            # Initialize cells with provided values and options
            values.each_with_index do |val, ci, cj|
                cell = @matrix[ci, cj]
                cell.value = val
                cell.options = options[ci, cj].dup if options.present?
            end
        end

        @confirmed_count = count_confirmed_values
        @rows = nil
        @columns = nil
        @blocks = nil
        @groups_cache = nil
    end

    attr_reader :confirmed_count

    # Return a deep copy of the puzzle matrix
    def duplicate
        Puzzle.new(source_matrix: self)
    end

    # Reset all cell options: filled cells get [], empty cells get full range
    def reset_options
        @matrix.each do |cell|
            if cell.value != 0
                cell.options = []
            else
                cell.options = Sudoku::VALUE_RANGE.dup
            end
        end
        invalidate_group_caches
    end

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
        (@rows ||= build_rows)[ci]
    end

    # Get an array of Group objects for the given range of rows
    def rows(range = Sudoku::COORD_RANGE)
        range.map { |num| row(num) }
    end

    # Get a column as a Group object
    def column(cj)
        (@columns ||= build_columns)[cj]
    end

    # Get an array of Group objects for all columns
    def columns
        Sudoku::COORD_RANGE.map { |num| column(num) }
    end

    # Get all row and column Group objects
    def vectors
        Sudoku::COORD_RANGE.flat_map { |num| [ row(num), column(num) ] }
    end

    # Get the Block object for the given block indices
    def block(ci, cj)
        (@blocks ||= build_blocks)[[ ci, cj ]]
    end

    # Returns the Block for the given cell using integer division for block indices
    def block_from_cell(cell)
        block_row = cell.ci / 3
        block_col = cell.cj / 3
        block(block_row, block_col)
    end

    # Get all Block objects in the puzzle
    def blocks
        [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ], [ 1, 0 ], [ 1, 1 ], [ 1, 2 ], [ 2, 0 ], [ 2, 1 ], [ 2, 2 ] ].map { |coords| block(coords[0], coords[1]) }
    end

    # Get all logical groups (rows, columns, and blocks)
    def groups
        @groups_cache ||= vectors + blocks
    end

    # Count the number of cells with a confirmed (nonzero) value
    def count_confirmed_values
        @matrix.count { |cell| !cell.empty? }
    end

    # Returns true if the puzzle is complete (all cells confirmed)
    def complete?
        update_confirmed_count
        @confirmed_count == 81
    end

    # Count the number of blank (zero) cells
    def count_blank_cells
        @matrix.count { |cell| cell.empty? }
    end

    # Return a matrix of cell values
    def values_matrix
        @matrix.map { |cell| cell.value }
    end

    # Return an array of cell values
    def values_array
        values_matrix.to_a
    end

    # Return a matrix of cell options
    def options_matrix
        @matrix.map { |cell| cell.options }
    end

    # Return an array of cell options
    def options_array
        options_matrix.to_a
    end

    # Return all sibling cells (same row, column, or block) for a given cell
    def siblings_of(cell)
        siblings = Set.new
        siblings.merge(row(cell.ci).cells)
        siblings.merge(column(cell.cj).cells)
        siblings.merge(block_from_cell(cell).cells)
        siblings.delete(cell)
        siblings
    end

    # Forbid this cell's value in all sibling cells (row, column, block)
    def forbid_cell_relatives(cell)
        row(cell.ci).forbid_value(cell.value)
        column(cell.cj).forbid_value(cell.value)
        block_from_cell(cell).forbid_value(cell.value)
    end

    # Count the number of empty cells with no options
    def optionless_cell_count
        @matrix.count do |cell|
            cell.value == 0 && cell.options.length == 0
        end
    end

    # Return the number of values remaining to be filled
    def values_remaining
        81 - count_confirmed_values
    end

    # Confirm a value in a cell, update relatives and confirmed count
    def confirm_cell(value, ci, cj)
        cell = cell(ci, cj)
        cell.evaluate_and_assign_value(value, self)
        forbid_cell_relatives(cell)
        update_confirmed_count
        invalidate_group_caches
    end

    # Update the confirmed count and return true if it changed
    def update_confirmed_count
        new_values_found = count_confirmed_values
        number_changed = new_values_found != @confirmed_count
        @confirmed_count = new_values_found
        number_changed
    end

    # Invalidate cached groupings (rows, columns, blocks, groups)
    # TODO: is this needed?
    def invalidate_group_caches
        @rows = nil
        @columns = nil
        @blocks = nil
        @groups_cache = nil
    end

    # Returns true if all groups are valid
    def valid?
        groups.all?(&:valid?)
    end

    # Returns true if the puzzle is valid and complete
    def valid_and_complete?
        valid? && complete?
    end

    private

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

    # Helper methods to build rows, columns, blocks, and groups for caching
    def build_rows
      rows_hash = {}
      Sudoku::COORD_RANGE.each do |ci|
        rows_hash[ci] = Group.new(@matrix.row(ci).to_a)
      end
      rows_hash
    end

    # Build columns as Group objects and return a hash mapping column index to Group
    def build_columns
      columns_hash = {}
      Sudoku::COORD_RANGE.each do |cj|
        columns_hash[cj] = Group.new(@matrix.column(cj).to_a)
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
