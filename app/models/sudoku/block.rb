##
# Block represents a 3x3 region in a Sudoku puzzle.
# Inherits from Group and provides logic for gathering and validating the cells in a block.
#
# Attributes:
#   row_number     - Integer (0-2), block row index
#   column_number  - Integer (0-2), block column index
#   cells          - Array of Cell objects in this block
#
# Methods:
#   convert_coordinates(i) - Returns the cell indices for a block index
#   coordinate_set         - Returns all [row, col] pairs in this block
#   gather_cells           - Collects all Cell objects in this block
#   values                 - Returns the values of all cells in this block
#   print_values           - Prints the values in block format

require_relative "sudoku"
require_relative "group"
require_relative "cell"

class Sudoku::Block < Sudoku::Group
    # Initialize a Block with a Puzzle and block indices (row_number, column_number).
    # Raises ArgumentError if arguments are invalid.
    def initialize(puzzle, row_number, column_number)
        # Validate puzzle type and interface
        unless puzzle.is_a?(Sudoku::Puzzle)
            raise ArgumentError, "Block initialization error: puzzle must be a Sudoku::Puzzle, got #{puzzle.class}"
        end

        # Validate row and column numbers
        unless (0..2).include?(row_number)
            raise ArgumentError, "Block initialization error: row_number must be an integer between 0 and 2, got #{row_number.inspect}"
        end
        unless (0..2).include?(column_number)
            raise ArgumentError, "Block initialization error: column_number must be an integer between 0 and 2, got #{column_number.inspect}"
        end
        @puzzle = puzzle
        @row_number = row_number
        @column_number = column_number
        @cells = gather_cells
        @group_type = :block
        @group_number = row_number * 3 + column_number

        super(@cells)
    end

    attr_reader :cells
    attr_reader :row_number
    attr_reader :column_number

    def inspect
        "#<Block row_number=#{row_number}, column_number=#{column_number}, cell_coordinates=#{coordinate_set}>"
    end

    # Convert block index (0, 1, 2) to corresponding cell indices (0-8)
    def convert_coordinates(i)
        case i
        when 0
            [ 0, 1, 2 ]
        when 1
            [ 3, 4, 5 ]
        when 2
            [ 6, 7, 8 ]
        end
    end

    # Returns all [row, col] coordinate pairs for this block
    def coordinate_set
        set = []
        row_coords = convert_coordinates(@row_number)
        col_coords = convert_coordinates(@column_number)
        row_coords.each do |rc|
            col_coords.each do |cc|
                set << [ rc, cc ]
            end
        end
        set
    end


    def validate_cell_order(cells)
        expected_coordinates = coordinate_set
        valid = true
        cells.each_with_index do |cell, index|
            expected_ci, expected_cj = expected_coordinates[index]
            if cell.ci != expected_ci || cell.cj != expected_cj
                valid = false
                break
            end
        end
        valid
    end

    # Collects and returns all Cell objects in this block
    def gather_cells
        return @cells if defined?(@cells) && @cells
        cells = []
        coordinate_set.each do |set|
            cells << @puzzle.cell(set[0], set[1])
        end
        @cells = cells
    end

    # Returns the values of all cells in this block
    def values
        @cells.collect { |cell| cell.value }
    end

    def find_cell_by_coordinates(coords)
        ci, cj = coords
        @cells[ci % 3 * 3 + cj % 3]
    end

    private
    attr_reader :puzzle
end
