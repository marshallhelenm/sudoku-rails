# frozen_string_literal: true

require "minitest/autorun"
require "matrix"
require "byebug"
require_relative "../../app/models/puzzle"
require_relative "../../app/models/cell"

class PuzzleTest < Minitest::Test
  def setup
    @valid_puzzle_array = [ [ 0, 0, 2, 8, 0, 0, 0, 0, 3 ], [ 6, 0, 3, 0, 4, 9, 2, 5, 0 ], [ 8, 4, 0, 0, 2, 3, 6, 9, 0 ], [ 0, 0, 8, 2, 3, 0, 9, 7, 0 ], [ 0, 2, 0, 0, 0, 0, 8, 3, 0 ], [ 0, 0, 6, 0, 0, 4, 1, 2, 0 ], [ 5, 9, 0, 4, 1, 0, 0, 8, 0 ], [ 0, 8, 0, 5, 0, 2, 0, 6, 0 ], [ 0, 0, 1, 0, 7, 8, 0, 4, 0 ] ]
    @solved_puzzle_array = [ [ 1, 3, 4, 8, 2, 7, 9, 6, 5 ], [ 6, 8, 2, 5, 3, 9, 4, 7, 1 ], [ 5, 9, 7, 4, 6, 1, 8, 3, 2 ], [ 4, 1, 5, 6, 7, 8, 3, 2, 9 ], [ 2, 6, 8, 1, 9, 3, 7, 5, 4 ], [ 9, 7, 3, 2, 5, 4, 1, 8, 6 ], [ 7, 2, 9, 3, 4, 6, 5, 1, 8 ], [ 8, 4, 6, 7, 1, 5, 2, 9, 3 ], [ 3, 5, 1, 9, 8, 2, 6, 4, 7 ] ]

    @values = Matrix[*@valid_puzzle_array]
    @options = Matrix.build(9) { Set.new(1..9) }
    @matrix = Puzzle.new(values: @values, options: @options)
  end

  def values_filled_count(puzzle_array)
    puzzle_array.flatten!.select { |v| v != 0 }.size
  end

  def test_initialize_valid
    assert_instance_of Puzzle, @matrix, "Should initialize a Puzzle with valid values and options"
    assert_equal 9, @matrix.cells.row_count, "Matrix should have 9 rows"
    assert_equal 9, @matrix.cells.column_count, "Matrix should have 9 columns"
  end

  def test_initialize_invalid_values
    bad_values = Matrix.build(9) { "a" }
    assert_raises(ArgumentError, "Should raise error for non-integer values") { Puzzle.new(values: bad_values) }
  end

  def test_initialize_invalid_options
    bad_options = Matrix.build(9) { [ 1, "a", 3 ] }
    assert_raises(ArgumentError, "Should raise error for non-integer options") { Puzzle.new(values: @values, options: bad_options) }
  end

  def test_duplicate
    dup = @matrix.duplicate
    refute_same @matrix, dup, "Duplicate should return a new Puzzle instance"
    assert_equal @matrix.values_array, dup.values_array, "Duplicate should have the same values"
  end

  def test_cell_and_cells
    cell = @matrix.cell(0, 0)
    assert_instance_of Cell, cell, "cell(i, j) should return a Cell"
    assert_equal 0, cell.ci
    assert_equal 0, cell.cj
    assert @matrix.cells.is_a?(Matrix), "cells should return a Matrix"
    assert @matrix.cells[0, 0].is_a?(Cell), "cells should contain Cell instances"
  end

  def test_row_and_column
    row = @matrix.row(0)
    col = @matrix.column(0)
    assert row.respond_to?(:cells), "row should respond to :cells"
    assert col.respond_to?(:cells), "column should respond to :cells"
  end

  def test_blocks
    blocks = @matrix.blocks
    assert_equal 9, blocks.size, "blocks should return 9 Block objects"
  end

  def test_groups
    groups = @matrix.groups
    assert groups.size > 0, "groups should return a non-empty array"
  end

  def test_count_confirmed_and_blank
    values_filled = values_filled_count(@valid_puzzle_array)
    blank_values = 81 - values_filled
    assert_equal values_filled, @matrix.count_confirmed_values, "All cells should be confirmed (nonzero) except for zeros"
    cell = @matrix.cells.find { |cell| !cell.empty? }
    cell.reset
    assert_equal values_filled - 1, @matrix.count_confirmed_values, "Confirmed values should decrease when a cell is set to 0"
    assert_equal blank_values + 1, @matrix.count_blank_cells, "Blank cells should increase when a cell is set to 0"
  end

  def test_values_and_options_matrix_array
    assert_equal @values.to_a.flatten, @matrix.values_array.flatten, "values_array should match the input values"
    assert_equal @options.to_a.flatten, @matrix.options_array.flatten(1), "options_array should match the input options"
  end

  def test_siblings_of
    cell = @matrix.cell(0, 0)
    siblings = @matrix.siblings_of(cell)
    assert siblings.all? { |sib| sib.is_a?(Cell) }, "All siblings should be Cell instances"
    refute_includes siblings, cell, "Siblings should not include the cell itself"
  end

    def test_forbid_cell_relatives
    cell = @matrix.cell(0, 0)
    cell.value = 5
    @matrix.forbid_cell_relatives(cell)
    siblings = @matrix.siblings_of(cell)
    siblings.each do |sib|
      refute_includes sib.options, 5, "Sibling should not include forbidden value"
    end
  end

  def test_optionless_cell_count
    cell = @matrix.cell(0, 0)
    cell.options = Set.new
    cell.value = 0
    assert_equal 1, @matrix.optionless_cell_count, "Should count cells with no options and value 0"
  end

  def test_values_remaining
    values_filled = values_filled_count(@valid_puzzle_array)
    values_remaining = 81 - values_filled
    assert_equal values_remaining, @matrix.values_remaining, "values_remaining should count the number of cells with value 0"
    @matrix.cells.find { |cell| !cell.empty? }.reset
    assert_equal values_remaining + 1, @matrix.values_remaining, "Should update when a cell is blanked"
  end

  def test_confirm_cell_and_update_confirmed_count
    filled_count = values_filled_count(@valid_puzzle_array)
    cell = @matrix.cells.find { |cell| !cell.empty? }
    value_to_assign = cell.value
    cell.reset
    changed = @matrix.update_confirmed_count
    assert changed, "Confirmed count should change after blanking a cell"
    assert_equal filled_count - 1, @matrix.count_confirmed_values, "Should confirm cell and update count"
    @matrix.confirm_cell(value_to_assign, cell.ci, cell.cj)
    assert_equal filled_count, @matrix.count_confirmed_values, "Should confirm cell and update count"
  end

  def test_valid_and_complete_and_valid
    # skip "Need to implement with a valid puzzle setup"
    assert @matrix.valid?, "Matrix should be valid initially"
    solved_puzzle = Puzzle.new(values: Matrix[*@solved_puzzle_array])
    assert solved_puzzle.complete_and_valid?, "Solved puzzle should be valid and complete initially"
    solved_puzzle.cell(0, 0).value = 0
    refute solved_puzzle.complete_and_valid?, "Matrix should not be complete if a cell is blank"
  end
end
