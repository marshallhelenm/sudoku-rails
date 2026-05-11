
##
# Cell represents a single cell in a Sudoku puzzle grid.
#
# Attributes:
#   value   - Integer (0-9), 0 means empty
#   ci      - Integer (0-8), row index
#   cj      - Integer (0-8), column index
#   options - Array of unique integers (1-9), possible values for the cell
#   puzzle  - Reference to the parent puzzle (required)
#
# Provides validation for all attributes and utility methods for Sudoku logic.
require "byebug"
require "sqids"

class Cell
    require_relative "sudoku"
    require_relative "sudoku_cache"
    VALUE_RANGE = Sudoku::VALUE_RANGE
    OPTIONS_RANGE = Sudoku::OPTIONS_RANGE
    @@sqids = Sqids.new(salt: "sudoku-puzzle-id-salt", alphabet: "0123456789abcdef", min_length: 6)

    attr_reader :puzzle

    # Initialize a Cell with value, row (ci), column (cj), options, and puzzle.
    # Raises ArgumentError if any attribute is invalid.

    def initialize(puzzle:, value:, ci:, cj:, options: fresh_options)
        @initializing = true
        @puzzle = puzzle
        self.value = value
        if ci < 0 || ci > 8
            raise ArgumentError, "ci (row index) must be between 0 and 8, got #{ci.inspect}"
        end
        if cj < 0 || cj > 8
            raise ArgumentError, "cj (column index) must be between 0 and 8, got #{cj.inspect}"
        end
        @ci = ci # row index
        @cj = cj # column index
        @id = generate_id
        if options.present?
            self.options = options
        else
            self.options = value == 0 ? fresh_options : Set.new
        end
        @initializing = false

        @cell_cache = SudokuCache.new({
            groups: { current: false, value: nil },
            row: { current: false, value: nil },
            column: { current: false, value: nil },
            block: { current: false, value: nil },
            siblings: { current: false, value: nil }
        })
    end


    attr_reader :ci, :cj, :id

    # Minimal inspect to avoid recursion/expensive output
    def inspect
        "#<Cell ci=#{@ci} cj=#{@cj} value=#{@value} options=#{@options.to_a}>"
    end

    def value
        @value
    end

    def options
        @options
    end

    # -- Custom attribute writers with validation --

    # Set the cell's value, must be integer 0-9
    def value=(val)
        validate_value(val)
        bust_caches if !@initializing && @value != val
        @value = val
    end

    # Set the cell's options, must be a set of unique integers 1-9
    def options=(opts)
        validate_options(opts)
        bust_caches if !@initializing && @options != opts
        @options = opts
    end

    def generate_id
        @@sqids.encode([ ci, cj ])
    end

    # -- Informational methods --

    # Return the cell's coordinates as [row, column]
    def coordinates
        [ @ci, @cj ]
    end

    # Returns the block row index for this cell (0-2)
    def block_i
        @ci / 3
    end

    # Returns the block column index for this cell (0-2)
    def block_j
        @cj / 3
    end

    # Returns the block coordinates as [row, col]
    def block_coordinates
        [ block_i, block_j ]
    end

    def self.block_coordinates_for(ci, cj)
        [ ci / 3, cj / 3 ]
    end

    def row
      @cell_cache.cache_or_compute(:row) { @puzzle.row(@ci) }
    end

    def column
        @cell_cache.cache_or_compute(:column) { @puzzle.column(@cj) }
    end

    def block
        @cell_cache.cache_or_compute(:block) { @puzzle.block(block_i, block_j) }
    end

    def groups
        @cell_cache.cache_or_compute(:groups) { [ row, column, block ] }
    end

    # Return all sibling cells (same row, column, or block) in the matrix
    def siblings
        @cell_cache.cache_or_compute(:siblings) do
            sibs = Set.new
            sibs.merge(row.cells)
            sibs.merge(column.cells)
            sibs.merge(block.cells)
            sibs.delete(self)
            sibs
        end
    end

    def sibling_values
        siblings.map(&:value).to_set
    end

    # -- Evaluative methods --

    # Returns true if the cell is empty (value == 0)
    def empty?
        self.value == 0
    end

    # Check if the cell can be the given number in the context of the matrix
    def can_be_in_matrix?(num, rewrite_options = false)
        temp_options = self.evaluate_options(rewrite_options)
        temp_options.include?(num)
    end

    # Check if the cell can be the given number (in options)
    def options_include?(num)
        self.options.include?(num)
    end

    # -- Utility methods for Sudoku logic --

    # Assign a value to the cell, optionally overwriting options check.
    # Raises error if value is not allowed and overwrite is false.
    def assign_value(val, overwrite = false)
        if overwrite
            self.value = val
            true
        else
            if self.options_include?(val)
                self.value = val
                true
            else
                false
            end
        end
    end

    # Reset the cell to empty and restore all options
    def reset
        self.value = 0
        self.options = fresh_options
    end

    # Reset only the cell's options to full range
    def reset_options
        self.options = fresh_options
    end

    # Remove multiple options from the cell's options set
    def forbid_multiple(options_to_forbid)
        options_to_forbid.each { |opt| self.options.delete(opt) }
        self.options
    end

    # Remove a single option from the cell's options set
    def forbid(option_to_forbid)
        self.options.delete(option_to_forbid)
        self.options
    end

    # Forbid this cell's value in all sibling cells in the matrix
    def forbid_siblings
        siblings.each { |sibling| sibling.forbid(self.value) }
    end

    # Evaluate and return possible options for this cell given the matrix.
    # If overwrite is true, update the cell's options.
    def evaluate_options(overwrite = false)
        temp_options = fresh_options
        siblings.each do |sibling|
            if sibling.value != 0
                temp_options.delete(sibling.value)
            end
        end
        self.options = temp_options if overwrite
        temp_options
    end

    def bust_caches
        groups.each(&:bust_cache)
        @puzzle.bust_info_cache
    end

    def confirm(value)
        self.evaluate_options(true)
        confirmed = self.assign_value(value)
        return false unless confirmed
        self.forbid_siblings
        true
    end


    private

    def fresh_options
        Set.new(OPTIONS_RANGE.dup)
    end

    def validate_value(val)
        unless val.is_a?(Integer) && VALUE_RANGE.include?(val)
            raise ArgumentError, "value must be an integer between #{VALUE_RANGE.first} and #{VALUE_RANGE.last}, got #{val.inspect}"
        end
    end

    def validate_index(val, name)
        unless val.is_a?(Integer) && (0..8).include?(val)
            raise ArgumentError, "#{name} must be an integer between 0 and 8, got #{val.inspect}"
        end
    end

    def validate_options(opts)
        unless opts.is_a?(Set) && opts.all? { |o| o.is_a?(Integer) && OPTIONS_RANGE.include?(o) } && opts.size == opts.to_a.uniq.size
            raise ArgumentError, "options must be a set of unique integers between #{OPTIONS_RANGE.first} and #{OPTIONS_RANGE.last}"
        end
    end
end
