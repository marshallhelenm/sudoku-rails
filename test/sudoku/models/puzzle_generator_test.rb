class Sudoku::PuzzleGeneratorTest < Minitest::Test
  require_relative "../../../app/models/sudoku/puzzle"
  require_relative "../../../app/models/sudoku/cell"
  require_relative "../../../app/models/sudoku/group"
  require_relative "../../../app/models/sudoku/puzzle_generator"

  def test_sort_groups_by_remaining_values
    @puzzle = Sudoku::Puzzle.new
    @generator = Sudoku::PuzzleGenerator.new
    # Set up a scenario where one group has fewer remaining values than the others
    row = @puzzle.row(0)
    row.cells.each_with_index do |cell, index|
      if index < 5
        cell.value = index + 1 # Fill in values 1-5 in the first 5 cells of the row
      end
    end
    sorted_groups = @generator.sort_groups_by_remaining_values(@puzzle)
    assert_equal [ row.group_type, row.group_number ], [ sorted_groups.first.group_type, sorted_groups.first.group_number ], "The group with the fewest remaining values should be first in the sorted list"
  end
end
