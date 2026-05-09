##
# Cell represents a single cell in a Sudoku puzzle grid.
#
# Attributes:
#   value   - Integer (0-9), 0 means empty
#   ci      - Integer (0-8), row index
#   cj      - Integer (0-8), column index
#   options - Array of unique integers (1-9), possible values for the cell
#
# Provides validation for all attributes and utility methods for Sudoku logic.
require "byebug"

class Cell
    require_relative "sudoku"
    VALUE_RANGE = Sudoku::VALUE_RANGE
    OPTIONS_RANGE = Sudoku::OPTIONS_RANGE
    # Initialize a Cell with value, row (ci), column (cj), and options.
    # Raises ArgumentError if any attribute is invalid.
    def initialize(value:, ci:, cj:, options: fresh_options)
        self.value = value
        self.ci = ci # row index
        self.cj = cj # column index
        if options.present?
            self.options = options
        else
            self.options = value == 0 ? fresh_options : Set.new
        end
    end

    # Custom attribute writers with validation
    # Get the cell's value (0-9, 0 means empty)
    def value
        @value
    end
    # Set the cell's value, must be integer 0-9
    def value=(val)
        validate_value(val)
        @value = val
    end

    # Get the cell's row index (0-8)
    def ci
        @ci
    end
    # Set the cell's row index, must be integer 0-8
    def ci=(val)
        validate_index(val, "ci")
        @ci = val
    end

    # Get the cell's column index (0-8)
    def cj
        @cj
    end
    def cj=(val)
        validate_index(val, "cj")
        @cj = val
    end

    # Get the cell's options (possible values, a set of unique integers 1-9)
    def options
        @options
    end
    # Set the cell's options, must be a set of unique integers 1-9
    def options=(opts)
        validate_options(opts)
        @options = opts
    end

    # Assign a value to the cell, optionally overwriting options check.
    # Raises error if value is not allowed and overwrite is false.
    def assign_value(val, overwrite = false)
        if overwrite
            self.value = val
        else
            unless self.options_include?(val)
                raise StandardError, "cell cannot be the provided value"
            end
            self.value = val
        end
    end

    # Assign a value to the cell after evaluating options in the given matrix.
    # Raises error if value is not allowed in context.
    def evaluate_and_assign_value(val, matrix)
        if self.options_include?(val) && can_be_in_matrix?(val, matrix, rewrite_options = false)
            self.value = val
        else
            false
        end
    end

    # Return the cell's coordinates as [row, column]
    def coordinates
        [ @ci, @cj ]
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

    # Return all sibling cells (same row, column, or block) in the matrix
    def siblings(matrix)
        matrix.siblings_of(self)
    end

    def sibling_values(matrix)
        siblings(matrix).map(&:value).to_set
    end

    # Forbid this cell's value in all sibling cells in the matrix
    def forbid_siblings(matrix)
        siblings(matrix).each { |sibling| sibling.forbid(self.value) }
    end

    # Check if the cell can be the given number (in options)
    def options_include?(num)
        self.options.include?(num)
    end

    # Evaluate and return possible options for this cell given the matrix.
    # If overwrite is true, update the cell's options.
    def evaluate_options(matrix, overwrite = false)
        temp_options = fresh_options
        siblings(matrix).each do |sibling|
            if sibling.value != 0
                temp_options.delete(sibling.value)
            end
        end
        self.options = temp_options if overwrite
        temp_options
    end

    # Check if the cell can be the given number in the context of the matrix
    def can_be_in_matrix?(num, matrix, rewrite_options = false)
        temp_options = self.evaluate_options(matrix, rewrite_options)
        temp_options.include?(num)
    end

    # Returns true if the cell is empty (value == 0)
    def empty?
        self.value == 0
    end

    # Returns the block row index for this cell (0-2)
    def block_i
        self.ci / 3
    end

    # Returns the block column index for this cell (0-2)
    def block_j
        self.cj / 3
    end

    # Returns the block coordinates as [row, col]
    def block_coordinates
        [ block_i, block_j ]
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
