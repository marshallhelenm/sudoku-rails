# Group represents a collection of Cell objects (row, column, or block) in a Sudoku puzzle.
# Provides validation and utility methods for group logic.

require_relative "sudoku"
require_relative "puzzle"
require_relative "group"

class Sudoku::Column < Sudoku::Group

    def initialize(cells)
        super(cells)
        @group_type = :column
        @group_number = cells.first.cj # all cells in the column should have the same cj (column index)
    end

    def find_cell_by_coordinates(coords)
        ci, cj = coords
        self.cells[ci]
    end

    def validate_cell_order(cells)
        (0..8).all? do |expected_ci|
            cells[expected_ci].ci == expected_ci
        end
    end
end
