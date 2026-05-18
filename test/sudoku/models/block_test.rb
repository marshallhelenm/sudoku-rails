# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../../app/models/sudoku/block"
require_relative "../../../app/models/sudoku/puzzle"
require_relative "../../../app/models/sudoku/cell"

class BlockTest < Minitest::Test
  def setup
    # Create a 9x9 grid of cells with incremental values for testing
    @puzzle = Sudoku::Puzzle.new
    @block = @puzzle.block(1, 1)
  end

  def test_initialize_valid
    assert_equal 1, @block.row_number, "Block row_number should be set correctly"
    assert_equal 1, @block.column_number, "Block column_number should be set correctly"
    assert_equal 9, @block.cells.size, "Block should have 9 cells"
  end

  def test_initialize_invalid_puzzle
    assert_raises(ArgumentError, "Should raise error for non-Puzzle puzzle") { Sudoku::Block.new("not_a_puzzle", 0, 0) }
    bad_puzzle = Object.new
    assert_raises(ArgumentError, "Should raise error if puzzle does not respond to #cell") { Sudoku::Block.new(bad_puzzle, 0, 0) }
  end

  def test_initialize_invalid_indices
    assert_raises(ArgumentError, "Should raise error for row_number out of range") { Sudoku::Block.new(@puzzle, -1, 0) }
    assert_raises(ArgumentError, "Should raise error for column_number out of range") { Sudoku::Block.new(@puzzle, 0, 3) }
  end

  def test_convert_coordinates
    assert_equal [ 0, 1, 2 ], @block.convert_coordinates(0), "convert_coordinates(0) should return [0, 1, 2]"
    assert_equal [ 3, 4, 5 ], @block.convert_coordinates(1), "convert_coordinates(1) should return [3, 4, 5]"
    assert_equal [ 6, 7, 8 ], @block.convert_coordinates(2), "convert_coordinates(2) should return [6, 7, 8]"
  end

  def test_coordinate_set
    expected = [
      [ 3, 3 ], [ 3, 4 ], [ 3, 5 ],
      [ 4, 3 ], [ 4, 4 ], [ 4, 5 ],
      [ 5, 3 ], [ 5, 4 ], [ 5, 5 ]
    ]
    assert_equal expected, @block.coordinate_set, "coordinate_set should return all [row, col] pairs in the block"
  end

  def test_gather_cells
    cells = @block.gather_cells
    assert_equal 9, cells.size, "gather_cells should return 9 cells"
    assert cells.all? { |cell| cell.is_a?(Sudoku::Cell) }, "All gathered cells should be Cell instances"
  end

  def test_values
    expected_values = @block.cells.map(&:value)
    assert_equal expected_values, @block.values, "values should return the values of all cells in the block"
  end

  def test_inspect
    expected_string = "#<Block row_number=1, column_number=1, cell_coordinates=#{ @block.coordinate_set }>"
    assert_equal expected_string, @block.inspect, "inspect should return a string representation of the block with its coordinates and cell positions"
  end
end
