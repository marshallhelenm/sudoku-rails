##
# Cell represents a single cell in a Sudoku puzzle grid.
#
# Attributes:
#   value   - Integer (0-9), 0 means empty
#   ci      - Integer (0-9), row index
#   cj      - Integer (0-9), column index
#   options - Array of unique integers (1-9), possible values for the cell
#
# Provides validation for all attributes and utility methods for Sudoku logic.
class Cell
    require_relative "sudoku"
    VALUE_RANGE = Sudoku::VALUE_RANGE
    OPTIONS_RANGE = Sudoku::OPTIONS_RANGE
    # Initialize a Cell with value, row (ci), column (cj), and options.
    # Raises ArgumentError if any attribute is invalid.
    def initialize(value:, ci:, cj:, options: [])
        self.value = value
        self.ci = ci # row index
        self.cj = cj # column index
        if options.present?
            self.options = options
        else
            self.options = value == 0 ? OPTIONS_RANGE : []
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

    # Get the cell's row index (0-9)
    def ci
        @ci
    end
    # Set the cell's row index, must be integer 0-9
    def ci=(val)
        validate_index(val, "ci")
        @ci = val
    end

    # Get the cell's column index (0-9)
    def cj
        @cj
    end
    # Set the cell's column index, must be integer 0-9
    def cj=(val)
        validate_index(val, "cj")
        @cj = val
    end

    # Get the cell's options (possible values, array of unique integers 1-9)
    def options
        @options
    end
    # Set the cell's options, must be array of unique integers 1-9
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
            unless self.can_be?(val)
                raise StandardError, "cell cannot be the provided value"
            end
            self.value = val
        end
    end

    # Assign a value to the cell after evaluating options in the given matrix.
    # Raises error if value is not allowed in context.
    def evaluate_and_assign_value(val, matrix)
        unless self.can_be?(val) && can_be_in_matrix?(val, matrix, rewrite_options = false)
            raise StandardError, "cell cannot be the provided value"
        end
        self.value = val
    end

    # Return the cell's coordinates as [row, column]
    def coordinates
        [ @ci, @cj ]
    end

    # Reset the cell to empty and restore all options
    def reset
        self.value = 0
        self.options = OPTIONS_RANGE
    end

    # Reset only the cell's options to full range
    def reset_options
        self.options = OPTIONS_RANGE
    end

    # Remove multiple options from the cell's options array
    def forbid_multiple(options_to_forbid)
        options_to_forbid.each { |opt| self.options.delete(opt) }
        self.options
    end

    # Remove a single option from the cell's options array
    def forbid(option_to_forbid)
        self.options.delete(option_to_forbid)
        self.options
    end

    # Return all sibling cells (same row, column, or block) in the matrix
    def siblings(matrix)
        matrix.siblings_of(self)
    end

    # Forbid this cell's value in all sibling cells in the matrix
    def forbid_siblings(matrix)
        siblings(matrix).each { |sibling| sibling.forbid(self.value) }
    end

    # Check if the cell can be the given number (in options)
    def can_be?(num)
        self.options.include?(num)
    end

    # Evaluate and return possible options for this cell given the matrix.
    # If overwrite is true, update the cell's options.
    def evaluate_options(matrix, overwrite = false)
        temp_options = OPTIONS_RANGE
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
        case self.ci
        when 0, 1, 2
            0
        when 3, 4, 5
            1
        when 6, 7, 8
            2
        end
    end

    # Returns the block column index for this cell (0-2)
    def block_j
        case self.cj
        when 0, 1, 2
            0
        when 3, 4, 5
            1
        when 6, 7, 8
            2
        end
    end

    # Returns the block coordinates as [row, col]
    def block_coordinates
        [ block_i, block_j ]
    end

    private

    def validate_value(val)
        unless val.is_a?(Integer) && VALUE_RANGE.include?(val)
            raise ArgumentError, "value must be an integer between \\#{VALUE_RANGE.first} and \\#{VALUE_RANGE.last}"
        end
    end

    def validate_index(val, name)
        unless val.is_a?(Integer) && VALUE_RANGE.include?(val)
            raise ArgumentError, "#{name} must be an integer between \\#{VALUE_RANGE.first} and \\#{VALUE_RANGE.last}"
        end
    end

    def validate_options(opts)
        unless opts.is_a?(Array) && opts.uniq.length == opts.length && opts.all? { |o| o.is_a?(Integer) && OPTIONS_RANGE.include?(o) }
            raise ArgumentError, "options must be an array of unique integers between \\#{OPTIONS_RANGE.first} and \\#{OPTIONS_RANGE.last}"
        end
    end
end
