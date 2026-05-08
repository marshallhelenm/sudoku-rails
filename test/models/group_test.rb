# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../app/models/group"
require_relative "../../app/models/cell"

class GroupTest < Minitest::Test
  def setup
    @cells = [
      Cell.new(value: 1, ci: 0, cj: 0, options: [ 1, 2, 3 ]),
      Cell.new(value: 2, ci: 0, cj: 1, options: [ 2, 3, 4 ]),
      Cell.new(value: 0, ci: 0, cj: 2, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 3, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 4, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 5, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 6, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 7, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]),
      Cell.new(value: 0, ci: 0, cj: 8, options: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ])
    ]
    @group = Group.new(@cells)
  end

  def test_initialize_valid
    assert_equal @cells, @group.cells, "Group should store the provided cells array"
    assert_equal [ 1, 2, 0, 0, 0, 0, 0, 0, 0 ], @group.values, "Group should store the correct values from cells"
  end

  def test_initialize_invalid
    assert_raises(ArgumentError, "Should raise error for non-Cell array") { Group.new([ 1, 2, 3 ]) }
    assert_raises(ArgumentError, "Should raise error for invalid Cell array length") { Group.new(Array.new(4) { |i| Cell.new(value: i, ci: 0, cj: i, options: [ 1, 2, 3 ]) }) }
    assert_raises(ArgumentError, "Should raise error for non-array input") { Group.new("not an array") }
  end

  def test_empty_cells
    empty = @group.empty_cells
    assert_equal 7, empty.size, "Should find seven empty cells in the group"
    assert_equal 0, empty.first.value, "Empty cell should have value 0"
  end

  def test_possible_values
    assert_equal (1..9).to_a, @group.possible_values, "Possible values should be 1 through 9"
  end

  def test_remaining_values
    assert_equal [ 3, 4, 5, 6, 7, 8, 9 ], @group.remaining_values, "Remaining values should exclude those already present"
  end

  def test_values_valid
    assert @group.values_valid?, "Values should be valid when unique"
    # Add a duplicate value
    @group.values << 1
    refute @group.values_valid?, "Values should be invalid if there are duplicates"
  end

  def test_options_valid
    assert @group.options_valid?, "Options should be valid when all remaining values are possible"
    # Remove all options from the empty cell
    @group.cells.last.options = []
    refute @group.options_valid?, "Options should be invalid if an empty cell has no options"
    # Remove a value from all options
    @group.cells.each { |c| c.options = [ 9 ] }
    refute @group.options_valid?, "Options should be invalid if a remaining value cannot be placed"
  end

  def test_valid
    assert @group.valid?, "Group should be valid when values and options are valid"
    @group.cells.last.options = []
    refute @group.valid?, "Group should be invalid if options are invalid"
    @group.values << 1
    refute @group.valid?, "Group should be invalid if values are invalid"
  end

  def test_forbid_value
    @group.forbid_value(2)
    refute @group.cells.any? { |c| c.options.include?(2) }, "forbid_value should remove the value from all cell options"
  end
end
