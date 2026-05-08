# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../app/models/cell"

class CellTest < Minitest::Test
  def setup
    @cell = Cell.new(value: 0, ci: 1, cj: 2)
  end

  def test_initialize_valid
    cell = Cell.new(value: 5, ci: 3, cj: 4, options: [ 1, 2, 3 ])
    assert_equal 5, cell.value, "Cell value should be set correctly on initialization"
    assert_equal 3, cell.ci, "Cell row index (ci) should be set correctly on initialization"
    assert_equal 4, cell.cj, "Cell column index (cj) should be set correctly on initialization"
    assert_equal [ 1, 2, 3 ], cell.options, "Cell options should be set correctly on initialization"
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
    assert_raises(ArgumentError, "Should raise error for options containing 0") { Cell.new(value: 0, ci: 1, cj: 1, options: [ 0, 1, 2 ]) }
    assert_raises(ArgumentError, "Should raise error for options with duplicates") { Cell.new(value: 0, ci: 1, cj: 1, options: [ 1, 1, 2 ]) }
    assert_raises(ArgumentError, "Should raise error for options containing > 9") { Cell.new(value: 0, ci: 1, cj: 1, options: [ 1, 2, 10 ]) }
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
    @cell.options = [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
    assert_equal [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ], @cell.options, "Options setter should update options correctly"
    assert_raises(ArgumentError, "Should raise error for duplicate options in setter") { @cell.options = [ 1, 2, 2 ] }
    assert_raises(ArgumentError, "Should raise error for options containing 0 in setter") { @cell.options = [ 0, 1, 2 ] }
  end

  def test_assign_value
    @cell.options = [ 1, 2, 3 ]
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
    @cell.options = [ 1, 2 ]
    @cell.reset
    assert_equal 0, @cell.value, "reset should set value to 0"
    assert_equal (1..9).to_a, @cell.options, "reset should set options to full range"
    @cell.options = [ 1, 2 ]
    @cell.reset_options
    assert_equal (1..9).to_a, @cell.options, "reset_options should set options to full range"
  end

  def test_forbid_and_forbid_multiple
    @cell.options = [ 1, 2, 3, 4 ]
    @cell.forbid(2)
    assert_equal [ 1, 3, 4 ], @cell.options, "forbid should remove a single value from options"
    @cell.forbid_multiple([ 1, 4 ])
    assert_equal [ 3 ], @cell.options, "forbid_multiple should remove multiple values from options"
  end

  def test_can_be
    @cell.options = [ 2, 3, 4 ]
    assert @cell.can_be?(2), "can_be? should return true if value is in options"
    refute @cell.can_be?(1), "can_be? should return false if value is not in options"
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
end
