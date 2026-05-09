# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../app/models/cell"
require_relative "../../app/models/puzzle"

class CellTest < Minitest::Test
  def setup
    @valid_puzzle_array = [ [ 0, 0, 2, 8, 0, 0, 0, 0, 3 ], [ 6, 0, 3, 0, 4, 9, 2, 5, 0 ], [ 8, 4, 0, 0, 2, 3, 6, 9, 0 ], [ 0, 0, 8, 2, 3, 0, 9, 7, 0 ], [ 0, 2, 0, 0, 0, 0, 8, 3, 0 ], [ 0, 0, 6, 0, 0, 4, 1, 2, 0 ], [ 5, 9, 0, 4, 1, 0, 0, 8, 0 ], [ 0, 8, 0, 5, 0, 2, 0, 6, 0 ], [ 0, 0, 1, 0, 7, 8, 0, 4, 0 ] ]
    @solved_puzzle_array = [ [ 1, 3, 4, 8, 2, 7, 9, 6, 5 ], [ 6, 8, 2, 5, 3, 9, 4, 7, 1 ], [ 5, 9, 7, 4, 6, 1, 8, 3, 2 ], [ 4, 1, 5, 6, 7, 8, 3, 2, 9 ], [ 2, 6, 8, 1, 9, 3, 7, 5, 4 ], [ 9, 7, 3, 2, 5, 4, 1, 8, 6 ], [ 7, 2, 9, 3, 4, 6, 5, 1, 8 ], [ 8, 4, 6, 7, 1, 5, 2, 9, 3 ], [ 3, 5, 1, 9, 8, 2, 6, 4, 7 ] ]
    @cell = Cell.new(value: 0, ci: 1, cj: 2)
  end

  def test_initialize_valid
    cell = Cell.new(value: 5, ci: 3, cj: 4, options: Set.new([ 1, 2, 3 ]))
    assert_equal 5, cell.value, "Cell value should be set correctly on initialization"
    assert_equal 3, cell.ci, "Cell row index (ci) should be set correctly on initialization"
    assert_equal 4, cell.cj, "Cell column index (cj) should be set correctly on initialization"
    assert_equal Set.new(1..3), cell.options, "Cell options should be set correctly on initialization"
  end

  def test_initialize_invalid_value
    assert_raises(ArgumentError, "Should raise error for value > 9") { Cell.new(value: 10, ci: 1, cj: 1) }
    assert_raises(ArgumentError, "Should raise error for value < 0") { Cell.new(value: -1, ci: 1, cj: 1) }
  end

  def test_initialize_invalid_indices
    assert_raises(ArgumentError, "Should raise error for ci > 9") { Cell.new(value: 1, ci: 10, cj: 1) }
    assert_raises(ArgumentError, "Should raise error for cj > 9") { Cell.new(value: 1, ci: 1, cj: 10) }
  end

  def test_initialize_invalid_options
    assert_raises(ArgumentError, "Should raise error for options containing 0") { Cell.new(value: 0, ci: 1, cj: 1, options: Set.new([ 0, 1, 2 ])) }
    assert_raises(ArgumentError, "Should raise error for options containing > 9") { Cell.new(value: 0, ci: 1, cj: 1, options: Set.new([ 1, 2, 10 ])) }
  end

  def test_value_setter
    @cell.value = 9
    assert_equal 9, @cell.value, "Value setter should update value correctly"
    assert_raises(ArgumentError, "Should raise error for value > 9 in setter") { @cell.value = 11 }
  end

  def test_ci_cj_setters
    @cell.ci = 5
    @cell.cj = 6
    assert_equal 5, @cell.ci, "ci setter should update row index correctly"
    assert_equal 6, @cell.cj, "cj setter should update column index correctly"
    assert_raises(ArgumentError, "Should raise error for ci < 0 in setter") { @cell.ci = -1 }
    assert_raises(ArgumentError, "Should raise error for cj > 9 in setter") { @cell.cj = 12 }
  end

  def test_options_setter
    @cell.options = Set.new(1..9)
    assert_equal Set.new(1..9), @cell.options, "Options setter should update options correctly"
    assert_raises(ArgumentError, "Should raise error for options containing 0 in setter") { @cell.options = Set.new([ 0, 1, 2 ]) }
  end

  def test_assign_value
    @cell.options = Set.new([ 1, 2, 3 ])
    assert_raises(StandardError, "Should raise error if value not in options") { @cell.assign_value(4) }
    @cell.assign_value(2)
    assert_equal 2, @cell.value, "assign_value should update value if in options"
    @cell.assign_value(5, true)
    assert_equal 5, @cell.value, "assign_value should update value if overwrite is true"
  end

  def test_coordinates
    assert_equal [ 1, 2 ], @cell.coordinates, "coordinates should return [ci, cj]"
  end

  def test_reset_and_reset_options
    @cell.value = 5
    @cell.options = Set.new([ 1, 2 ])
    @cell.reset
    assert_equal 0, @cell.value, "reset should set value to 0"
    assert_equal Set.new(1..9), @cell.options, "reset should set options to full range"
    @cell.options = Set.new([ 1, 2 ])
    @cell.reset_options
    assert_equal Set.new(1..9), @cell.options, "reset_options should set options to full range"
  end

  def test_forbid_and_forbid_multiple
    @cell.options = Set.new([ 1, 2, 3, 4 ])
    @cell.forbid(2)
    assert_equal Set.new([ 1, 3, 4 ]), @cell.options, "forbid should remove a single value from options"
    @cell.forbid_multiple([ 1, 4 ])
    assert_equal Set.new([ 3 ]), @cell.options, "forbid_multiple should remove multiple values from options"
  end

  def test_can_be
    @cell.options = Set.new([ 2, 3, 4 ])
    assert @cell.options_include?(2), "options_include? should return true if value is in options"
    refute @cell.options_include?(1), "options_include? should return false if value is not in options"
  end

  def test_empty
    @cell.value = 0
    assert @cell.empty?, "empty? should return true if value is 0"
    @cell.value = 5
    refute @cell.empty?, "empty? should return false if value is not 0"
  end

  def test_block_i_j_coordinates
    cell = Cell.new(value: 0, ci: 4, cj: 7)
    assert_equal 1, cell.block_i, "block_i should return correct block row index"
    assert_equal 2, cell.block_j, "block_j should return correct block column index"
    assert_equal [ 1, 2 ], cell.block_coordinates, "block_coordinates should return [block_i, block_j]"
  end

  def test_siblings
    @valid_puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    cell = @valid_puzzle.cell(0, 0)
    siblings = cell.siblings(@valid_puzzle)
    assert siblings.is_a?(Set), "siblings should return a set"
    assert siblings.all? { |s| s.is_a?(Cell) }, "All siblings should be Cell instances"
    assert siblings.include?(@valid_puzzle.cell(0, 1)), "Siblings should include cells in the same row"
    assert siblings.include?(@valid_puzzle.cell(1, 0)), "Siblings should include cells in the same column"
    assert siblings.include?(@valid_puzzle.cell(1, 1)), "Siblings should include cells in the same block"
    refute siblings.include?(cell), "Siblings should not include the cell itself"
    assert_equal 20, siblings.size, "A cell should have 20 siblings (8 in row + 8 in column + 4 in block)"
  end

  def test_sibling_values
    @valid_puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    cell = @valid_puzzle.cell(0, 0)
    sibling_values = cell.sibling_values(@valid_puzzle)
    assert sibling_values.is_a?(Set), "sibling_values should return a set"
    assert sibling_values.all? { |v| v.is_a?(Integer) }, "All sibling values should be integers"
    expected_values = cell.siblings(@valid_puzzle).map(&:value).to_set
    assert_equal expected_values, sibling_values, "sibling_values should match the values of the siblings"
  end

  def test_evaluate_options
    @valid_puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    cell = @valid_puzzle.cell(0, 0)
    options = cell.evaluate_options(@valid_puzzle)
    assert options.is_a?(Set), "evaluate_options should return a set"
    assert options.all? { |o| o.is_a?(Integer) }, "All evaluated options should be integers"
    expected_options = Set.new(1..9) - cell.sibling_values(@valid_puzzle)
    assert_equal expected_options, options, "evaluate_options should return the correct set of possible values"
  end

  def test_forbid_siblings
    @valid_puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    cell = @valid_puzzle.cells.find { |c| !c.empty? }
    val = cell.value
    cell.forbid_siblings(@valid_puzzle)
    siblings = cell.siblings(@valid_puzzle)
    siblings.each do |sibling|
      refute sibling.options.include?(val), "forbid_siblings should remove the cell's value from all siblings' options"
    end
  end

  def test_can_be_in_matrix
    @valid_puzzle = Puzzle.new(values: Matrix[*@valid_puzzle_array])
    cell = @valid_puzzle.cells.find { |c| !c.empty? }
    val = cell.value
    bad_val = cell.sibling_values(@valid_puzzle).first
    cell.reset
    assert cell.can_be_in_matrix?(val, @valid_puzzle), "can_be_in_matrix? should return true for a valid option"
    refute cell.can_be_in_matrix?(bad_val, @valid_puzzle), "can_be_in_matrix? should return false for an invalid option"
  end
end
