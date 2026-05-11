class PuzzleSolverTest < Minitest::Test
  require_relative "../../app/models/puzzle"
  require_relative "../../app/models/cell"
  require_relative "../../app/models/group"
  require_relative "../../app/models/puzzle_solver"

  def setup
    # @valid_puzzle_array = [ [ 0, 0, 2, 8, 0, 0, 0, 0, 3 ], [ 6, 0, 3, 0, 4, 9, 2, 5, 0 ], [ 8, 4, 0, 0, 2, 3, 6, 9, 0 ], [ 0, 0, 8, 2, 3, 0, 9, 7, 0 ], [ 0, 2, 0, 0, 0, 0, 8, 3, 0 ], [ 0, 0, 6, 0, 0, 4, 1, 2, 0 ], [ 5, 9, 0, 4, 1, 0, 0, 8, 0 ], [ 0, 8, 0, 5, 0, 2, 0, 6, 0 ], [ 0, 0, 1, 0, 7, 8, 0, 4, 0 ] ]
    # @puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    @puzzle = Puzzle.new
    @solver = PuzzleSolver.new(@puzzle)
  end

  def test_find_only_possible_cell_for_value_in_group
    group = @puzzle.row(0) # Get the first row group
    only_cell = @solver.find_only_possible_cell_for_value_in_group(group, 5)
    assert_nil only_cell, "Should return nil if no cell can only be the given value in the group"

    # construct a scenario where only one cell in the group can be 5
    group.cells.each_with_index do |cell, index|
      if index == 0
        cell.options = Set.new([  4, 5 ])
      else
        cell.forbid(5)
      end
    end
    only_cell = @solver.find_only_possible_cell_for_value_in_group(group, 5)
    assert_equal [ 0, 0 ], only_cell, "Should find the only possible cell for the value in the group"
  end

  def test_find_cells_that_can_only_be_one_value
    # construct a scenario where one cell has only one option
    cell = @puzzle.cells.to_a.flatten!.sample
    cell.options = Set.new([ 5 ])
    found_new = @solver.find_cells_that_can_only_be_one_value
    assert found_new, "Should find a cell that can only be one value"
    assert_equal 5, cell.value, "Should confirm the value of the cell that can only be one value"
  end
end
