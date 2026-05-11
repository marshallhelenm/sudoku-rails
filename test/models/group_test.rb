# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../app/models/group"
require_relative "../../app/models/cell"

class GroupTest < Minitest::Test
  def setup
    @puzzle = Puzzle.new(values: Matrix.build(9) { 0 }, options: Matrix.build(9) { Set.new(1..9) })
    @puzzle.cell(0, 0).value = 1
    @puzzle.cell(0, 1).value = 2
    @group = @puzzle.row(0)
  end

  def test_initialize_valid
    assert_equal 9, @group.cells.size, "Group should have 9 cells"
    assert @group.cells.all? { |c| c.is_a?(Cell) }, "All group members should be Cell objects"
    assert_equal [ 1, 2, 0, 0, 0, 0, 0, 0, 0 ], @group.values, "Group should store the correct values from cells"
  end

  def test_initialize_invalid
    assert_raises(ArgumentError, "Should raise error for non-Cell array") { Group.new([ 1, 2, 3 ]) }
    assert_raises(ArgumentError, "Should raise error for invalid Cell array length") { Group.new(Array.new(4) { |i| Cell.new(puzzle: @dummy_puzzle, value: i, ci: 0, cj: i, options: Set.new([ 1, 2, 3 ])) }) }
    assert_raises(ArgumentError, "Should raise error for non-array input") { Group.new("not an array") }
  end

  def test_blank_cells
    empty = @group.blank_cells
    assert_equal 7, empty.size, "Should find seven empty cells in the group"
    assert_equal 0, empty.first.value, "Empty cell should have value 0"
  end


  def test_complete_and_incomplete
    refute @group.complete?, "Group should not be complete if any cell is empty"
    assert @group.incomplete?, "Group should be incomplete if any cell is empty"
    # Fill all cells
    @group.cells.each_with_index { |cell, idx| cell.value = idx + 1 }
    assert @group.complete?, "Group should be complete if all cells are filled"
    refute @group.incomplete?, "Group should not be incomplete if all cells are filled"
  end

  def test_remaining_values
    assert_equal Set.new([ 3, 4, 5, 6, 7, 8, 9 ]), @group.remaining_values, "Remaining values should exclude those already present"
  end

  def test_values_valid
    assert @group.values_valid?, "Values should be valid when unique"
    # Add a duplicate value by setting a cell's value
    @group.cells[2].value = 1
    refute @group.values_valid?, "Values should be invalid if there are duplicates"
  end

  def test_options_valid
    assert @group.options_valid?, "Options should be valid when all remaining values are possible"
    # Remove all options from the empty cell
    @group.cells.last.options = Set.new
    refute @group.options_valid?, "Options should be invalid if an empty cell has no options"
    # Remove a value from all options
    @group.cells.each { |c| c.options = Set.new([ 9 ]) }
    refute @group.options_valid?, "Options should be invalid if a remaining value cannot be placed"
  end

  def test_valid
    assert @group.valid?, "Group should be valid when values and options are valid"
    @group.cells.last.options = Set.new
    refute @group.valid?, "Group should be invalid if options are invalid"
    # Reset options for last cell, then add duplicate value
    @group.cells.last.options = Set.new([ 1, 2, 3, 4, 5, 6, 7, 8, 9 ])
    @group.cells[2].value = 1
    refute @group.valid?, "Group should be invalid if values are invalid"
  end

  def test_forbid_value
    @group.forbid_value(2)
    refute @group.cells.any? { |c| c.options.include?(2) }, "forbid_value should remove the value from all cell options"
  end

  def test_validate_cell_order
    # This method is meant to be overridden in subclasses, so it should return true by default
    assert @group.validate_cell_order(@group.cells), "validate_cell_order should return true by default"
  end

  def test_validate_cell_order_for_row
    row = @puzzle.row(0)
    assert row.validate_cell_order(row.cells), "Row should validate correct cell order"
    # Create an invalid order by shuffling the cells
    shuffled_cells = row.cells.shuffle
    refute row.validate_cell_order(shuffled_cells), "Row should not validate incorrect cell order"
  end

  def test_validate_cell_order_for_column
    column = @puzzle.column(0)
    assert column.validate_cell_order(column.cells), "Column should validate correct cell order"
    # Create an invalid order by shuffling the cells
    shuffled_cells = column.cells.shuffle
    refute column.validate_cell_order(shuffled_cells), "Column should not validate incorrect cell order"
  end

  def test_validate_cell_order_for_block
    block = @puzzle.block(0, 0)
    assert block.validate_cell_order(block.cells), "Block should validate correct cell order"
    # Create an invalid order by shuffling the cells
    shuffled_cells = block.cells.shuffle
    refute block.validate_cell_order(shuffled_cells), "Block should not validate incorrect cell order"
  end

  def test_find_cell_by_coordinates_for_row
    cell = @group.find_cell_by_coordinates([ 0, 1 ])
    assert_equal @group.cells[1].coordinates, cell.coordinates, "Should find the correct cell by coordinates in the row"
  end

  def test_find_cell_by_coordinates_for_column
    column = @puzzle.column(0)
    cell = column.find_cell_by_coordinates([ 1, 0 ])
    assert_equal column.cells[1].coordinates, cell.coordinates, "Should find the correct cell by coordinates in the column"
  end

  def test_find_cell_by_coordinates_for_block
    block = @puzzle.block(0, 0)
    cell = block.find_cell_by_coordinates([ 1, 1 ])
    assert_equal block.cells[4].coordinates, cell.coordinates, "Should find the correct cell by coordinates in the block"
  end

  def test_group_number_and_type
    row = @puzzle.row(0)
    column = @puzzle.column(0)
    block = @puzzle.block(0, 0)
    assert_equal 0, row.group_number, "Row group number should match the row index"
    assert_equal :row, row.group_type, "Row group type should be :row"
    assert_equal 0, column.group_number, "Column group number should match the column index"
    assert_equal :column, column.group_type, "Column group type should be :column"
    assert_equal 0, block.group_number, "Block group number should be calculated from block indices"
    assert_equal :block, block.group_type, "Block group type should be :block"
  end
end
