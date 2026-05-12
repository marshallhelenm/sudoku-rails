unless defined?(Turbo) # stub Turbo for tests to avoid errors when broadcasting to the channel
    module Turbo
        class StreamsChannel
            def self.broadcast_action_to(*args, **kwargs)
              # no-op for tests
            end
        end
    end
end

class PuzzleSolverTest < Minitest::Test
  require_relative "../../app/models/puzzle"
  require_relative "../../app/models/cell"
  require_relative "../../app/models/group"
  require_relative "../../app/models/puzzle_solver"

  def setup
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

  def test_find_families_in_group
    group = @puzzle.row(0) # Get the first row group
    # construct a scenario where there are two families in the group
    options = [
      Set.new([ 1, 4 ]),
      Set.new([ 1, 4 ]),
      Set.new([ 2 ]),
      Set.new([ 5, 6 ]),
      Set.new([ 1, 5, 6, 7, 8, 9 ]),
      Set.new([ 1, 5, 6, 7, 8, 9 ]),
      Set.new([ 1, 6, 7, 8, 9 ]),
      Set.new([ 1, 6, 8, 9 ]),
      Set.new([ 3 ])
    ]
    # values with too many possible cells in the group to be a family:
    # - 1, 6, 8, 9
    # families to find:
    # - 4: cells 0 and 1
    # - 5: cells 3 and 4 and 5
    # - 7: cells 4 and 5 and 6
    # confirmable cells to find:
    # - 2: cell 2
    # - 3: cell 8

    group.cells.each do |cell|
      next if cell.value != 0
      cell.options = options.shift()
    end
    families = @solver.find_families_in_group(group)
    assert families.is_a?(Hash), "Should return a hash of families"
    assert_equal 3, families.keys.length, "Should find the correct number of families in the group"
    assert_equal [ group.cells[0].coordinates, group.cells[1].coordinates ], families[4], "Should find the family of cells that can be the value in the group"
    assert_equal [ group.cells[3].coordinates, group.cells[4].coordinates, group.cells[5].coordinates ], families[5], "Should find the family of cells that can be the value in the group"
    assert_nil families[1], "Should not find a family for a value that has more than 3 possible cells in the group"
    assert_nil families[9], "Should not find a family for a value that has more than 3 possible cells in the group"
    assert_equal 3, group.cells.last.value, "Should confirm a cell that is the only possible cell for a value in the group"
  end

  def test_find_families_in_group_with_invalid_group
    group = @puzzle.row(1) # Get the second row group
    # construct a scenario where there is an invalid group with a value that has no possible cells
    options = [
      Set.new([ 1, 4 ]),
      Set.new([ 1, 4 ]),
      Set.new([ 2 ]),
      Set.new([ 5, 6 ]),
      Set.new([ 1, 5, 6, 7, 8, 9 ]),
      Set.new([ 1, 5, 6, 7, 8, 9 ]),
      Set.new([ 1, 6, 7, 8, 9 ]),
      Set.new([ 1, 6, 8, 9 ]),
      Set.new([ 1, 6, 8, 9 ])
    ]
    # no cells can be 3 in this group, which should make the group invalid and cause the method to return false
    group.cells.each do |cell|
      next if cell.value != 0
      cell.options = options.pop()
    end
    families = @solver.find_families_in_group(group)
    assert_equal false, families, "Should return false if the group is invalid and has a value with no possible cells in the group"
  end

  def test_cell_can_be_part_of_extended_family?
    cell = @puzzle.cell(0, 0)
    cell.options = Set.new([ 1, 2, 3 ])
    assert @solver.cell_can_be_part_of_extended_family?(cell, [ 1, 2, 3 ]), "Cell should be able to be part of an extended family if all of its options are in the number options"
    assert @solver.cell_can_be_part_of_extended_family?(cell, [ 1, 2, 3, 4 ]), "Cell should be able to be part of an extended family if all of its options are in the number options, even if there are extra number options"
    refute @solver.cell_can_be_part_of_extended_family?(cell, [ 1 ]), "Cell should not be able to be part of an extended family if not all of its options are in the number options"
    refute @solver.cell_can_be_part_of_extended_family?(cell, [ 5 ]), "Cell should not be able to be part of an extended family if none of its options are in the number options"
  end

  class ForbidOtherCellsInGroupForFamilyTest < ActiveSupport::TestCase
    def setup
      @puzzle = Puzzle.new
      @solver = PuzzleSolver.new(@puzzle)
    end

    def logic_to_test_forbid_single_value_for_group(family, group)
      # construct a situation where a family of 3 cells in the row can be 5, and those three cells all fall in the same block.
      group.cells.each_with_index do |cell|
        next if family.include?(cell.coordinates)
        cell.forbid(5)
      end
      result = @solver.forbid_other_cells_in_group_for_family(value: 5, family: family, group: group)
      assert_equal true, result, "Should return true if the family falls within a single group"
      group.cells.each do |cell|
        if family.include?(cell.coordinates)
          assert cell.options_include?(5), "Should not forbid the value for cells in the family"
        else
          refute cell.options_include?(5), "Should forbid the value for cells not in the family that are in the same group"
        end
      end
    end

    def logic_to_test_forbid_single_value_for_group_with_invalid_family(family, group)
      # construct a situation where a family of 3 cells in the row can be 5, but those three cells do not all fall in the same block.
      group.cells.each_with_index do |cell|
        next if family.include?(cell.coordinates)
        cell.forbid(5)
      end
      cache_options = group.cells.map(&:options).to_s
      result = @solver.forbid_other_cells_in_group_for_family(value: 5, family: family, group: group)
      assert_equal false, result, "Should return false if the family doesn't fall within a single block"
      assert_equal cache_options, group.cells.map(&:options).to_s, "Should not forbid the value for any cells if the family doesn't fall within a single block"
    end

    def test_forbid_single_value_for_block
      block = @puzzle.block(0, 0)
      family = [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_single_value_for_group(family, block)
      invalid_family = [ [ 0, 0 ], [ 4, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_single_value_for_group_with_invalid_family(invalid_family, block)
    end

    def test_forbid_single_value_for_column
      column = @puzzle.column(0) # The first column of the puzzle
      # construct a situation where a family of 3 cells in the column can be 5, and those three cells fall in the same column.
      family = [ [ 0, 0 ], [ 1, 0 ], [ 2, 0 ] ]
      logic_to_test_forbid_single_value_for_group(family, column)
      # construct a situation where a family of 3 cells in the column can be 5, but those three cells do not all fall in the same column.
      invalid_family = [ [ 0, 0 ], [ 1, 1 ], [ 2, 0 ] ]
      logic_to_test_forbid_single_value_for_group_with_invalid_family(invalid_family, column)
    end

    def logic_to_test_forbid_multiple_values_for_group(family, group)
      group.cells.each_with_index do |cell|
        next if family.include?(cell.coordinates)
        cell.forbid_multiple([ 5, 6 ])
      end
      @solver.forbid_other_cells_in_group_for_family(values: [ 5, 6 ], family: family, group: group)
      group.cells.each do |cell|
        if family.include?(cell.coordinates)
          assert cell.options_include?(5), "Should not forbid the value for cells in the family"
          assert cell.options_include?(6), "Should not forbid the value for cells in the family"
        else
          refute cell.options_include?(5), "Should forbid the value for cells not in the family that are in the same group"
          refute cell.options_include?(6), "Should forbid the value for cells not in the family that are in the same group"
        end
      end
    end
    def logic_to_test_forbid_multiple_values_for_group_with_invalid_family(family, group)
      group.cells.each_with_index do |cell|
        next if family.include?(cell.coordinates)
        cell.forbid_multiple([ 5, 6 ])
      end
      cache_options = group.cells.map(&:options).to_s
      result = @solver.forbid_other_cells_in_group_for_family(values: [ 5, 6 ], family: family, group: group)
      assert_equal false, result, "Should return false if the family doesn't fall within a single group"
      assert_equal cache_options, group.cells.map(&:options).to_s, "Should not forbid the value for any cells if the family doesn't fall within a single block"
    end
    def test_forbid_multiple_values_for_block
      block = @puzzle.block(0, 0)
      family = [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_multiple_values_for_group(family, block)
      invalid_family = [ [ 0, 0 ], [ 4, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_multiple_values_for_group_with_invalid_family(invalid_family, block)
    end

    def test_forbid_multiple_values_for_row
      row = @puzzle.row(0) # The top row of the puzzle
      family = [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_multiple_values_for_group(family, row)
      invalid_family = [ [ 0, 0 ], [ 1, 1 ], [ 0, 2 ] ]
      logic_to_test_forbid_multiple_values_for_group_with_invalid_family(invalid_family, row)
    end

    def test_forbid_multiple_values_for_column
      column = @puzzle.column(0) # The leftmost column of the puzzle
      family = [ [ 0, 0 ], [ 1, 0 ], [ 2, 0 ] ]
      logic_to_test_forbid_multiple_values_for_group(family, column)
      invalid_family = [ [ 0, 0 ], [ 1, 1 ], [ 2, 0 ] ]
      logic_to_test_forbid_multiple_values_for_group_with_invalid_family(invalid_family, column)
    end
  end

  def test_find_extended_family_in_group
    group = @puzzle.row(0) # Get the first row group
    options = [
      Set.new([ 1, 4 ]),
      Set.new([ 1, 4 ]),
      Set.new([ 7, 8, 9 ]),
      Set.new([ 8, 9 ]),
      Set.new([ 7, 9 ]),
      Set.new([ 2 ]),
      Set.new([ 5, 6 ]),
      Set.new([ 1, 6, 9 ]),
      Set.new([ 3 ])
    ]
    group.cells.each do |cell|
      next if cell.value != 0
      cell.options = options.shift()
    end
    family = @solver.find_extended_family_in_group(group, [ 1, 4 ])
    assert_equal [ group.cells[0].coordinates, group.cells[1].coordinates ], family, "Should find the extended family of cells that can be the provided values in the group"

    family = @solver.find_extended_family_in_group(group, [ 7, 8, 9 ])
    assert_equal [ group.cells[2].coordinates, group.cells[3].coordinates, group.cells[4].coordinates ], family, "Should find the extended family of cells that can be the provided values in the group, even if not every member of the family can be every value in the number options"

    no_family = @solver.find_extended_family_in_group(group, [ 1, 2, 3 ])
    assert_nil no_family, "Should return nil if there is no extended family of cells that can be the value in the group"
  end
end
