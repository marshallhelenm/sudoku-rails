# Group represents a collection of Cell objects (row, column, or block) in a Sudoku puzzle.
# Provides validation and utility methods for group logic.

class Row < Group
    require_relative "sudoku_cache"
    require_relative "puzzle"

    def initialize(cells)
        super(cells)
        @group_type = :row
        @group_number = cells.first.ci # all cells in the row should have the same ci (row index)
    end

    def find_cell_by_coordinates(coords)
        ci, cj = coords
        self.cells[cj]
    end

    def validate_cell_order(cells)
        (0..8).all? do |expected_cj|
            cells[expected_cj].cj == expected_cj
        end
    end
end
