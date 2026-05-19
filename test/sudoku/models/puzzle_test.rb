# frozen_string_literal: true

require "minitest/autorun"
require "matrix"
require "byebug"
require_relative "../../../app/models/sudoku/puzzle"
require_relative "../../../app/models/sudoku/cell"

class PuzzleTest < Minitest::Test
  def setup
    @valid_puzzle_array = [ [ 0, 0, 2, 8, 0, 0, 0, 0, 3 ], [ 6, 0, 3, 0, 4, 9, 2, 5, 0 ], [ 8, 4, 0, 0, 2, 3, 6, 9, 0 ], [ 0, 0, 8, 2, 3, 0, 9, 7, 0 ], [ 0, 2, 0, 0, 0, 0, 8, 3, 0 ], [ 0, 0, 6, 0, 0, 4, 1, 2, 0 ], [ 5, 9, 0, 4, 1, 0, 0, 8, 0 ], [ 0, 8, 0, 5, 0, 2, 0, 6, 0 ], [ 0, 0, 1, 0, 7, 8, 0, 4, 0 ] ]
    @solved_puzzle_array = [ [ 1, 3, 4, 8, 2, 7, 9, 6, 5 ], [ 6, 8, 2, 5, 3, 9, 4, 7, 1 ], [ 5, 9, 7, 4, 6, 1, 8, 3, 2 ], [ 4, 1, 5, 6, 7, 8, 3, 2, 9 ], [ 2, 6, 8, 1, 9, 3, 7, 5, 4 ], [ 9, 7, 3, 2, 5, 4, 1, 8, 6 ], [ 7, 2, 9, 3, 4, 6, 5, 1, 8 ], [ 8, 4, 6, 7, 1, 5, 2, 9, 3 ], [ 3, 5, 1, 9, 8, 2, 6, 4, 7 ] ]

    @values = Matrix[*@valid_puzzle_array]
    @options = Matrix.build(9) { Set.new(1..9) }
    @puzzle = Sudoku::Puzzle.new(values: @values, options: @options)
  end

  def values_filled_count(puzzle_array)
    puzzle_array.flatten!.select { |v| v != 0 }.size
  end

  def test_initialize_valid
    assert_instance_of Sudoku::Puzzle, @puzzle, "Should initialize a Puzzle with valid values and options"
    assert_equal 9, @puzzle.cells.row_count, "Puzzle should have 9 rows"
    assert_equal 9, @puzzle.cells.column_count, "Puzzle should have 9 columns"
  end

  def test_initialize_invalid_values
    bad_values = Matrix.build(9) { "a" }
    assert_raises(ArgumentError, "Should raise error for non-integer values") { Sudoku::Puzzle.new(values: bad_values) }
  end

  def test_initialize_invalid_options
    bad_options = Matrix.build(9) { [ 1, "a", 3 ] }
    assert_raises(ArgumentError, "Should raise error for non-integer options") { Sudoku::Puzzle.new(values: @values, options: bad_options) }
  end

  def test_duplicate
    dup = @puzzle.duplicate
    refute_same @puzzle.id, dup.id, "Duplicate should have a different ID"
    assert_equal @puzzle.values_array, dup.values_array, "Duplicate should have the same values"
    assert_equal @puzzle.options_array, dup.options_array, "Duplicate should have the same options"
  end

  def test_cell_and_cells
    cell = @puzzle.cell(0, 0)
    assert_instance_of Sudoku::Cell, cell, "cell(i, j) should return a Cell"
    assert_equal 0, cell.ci
    assert_equal 0, cell.cj
    assert @puzzle.cells.is_a?(Matrix), "cells should return a Matrix"
    assert @puzzle.cells[0, 0].is_a?(Sudoku::Cell), "cells should contain Cell instances"
  end

  def test_row_and_column
    row = @puzzle.row(0)
    col = @puzzle.column(0)
    assert row.respond_to?(:cells), "row should respond to :cells"
    assert col.respond_to?(:cells), "column should respond to :cells"
  end

  def test_blocks
    blocks = @puzzle.blocks
    assert_equal 9, blocks.size, "blocks should return 9 Block objects"
  end

  def test_groups
    groups = @puzzle.groups
    assert groups.size > 0, "groups should return a non-empty array"
  end

  def test_count_confirmed_and_blank
    values_filled = values_filled_count(@valid_puzzle_array)
    blank_values = 81 - values_filled
    assert_equal values_filled, @puzzle.count_confirmed_values, "All cells should be confirmed (nonzero) except for zeros"
    cell = @puzzle.cells.find { |cell| !cell.empty? }
    cell.reset
    assert_equal values_filled - 1, @puzzle.count_confirmed_values, "Confirmed values should decrease when a cell is set to 0"
    assert_equal blank_values + 1, @puzzle.count_blank_cells, "Blank cells should increase when a cell is set to 0"
  end

  def test_values_and_options_matrix_array
    assert_equal @values.to_a.flatten, @puzzle.values_array.flatten, "values_array should match the input values"
    assert_equal @options.to_a.flatten, @puzzle.options_array.flatten(1), "options_array should match the input options"
  end

  def test_optionless_cell_count
    cell = @puzzle.cell(0, 0)
    cell.options = Set.new
    cell.value = 0
    assert_equal 1, @puzzle.optionless_cell_count, "Should count cells with no options and value 0"
  end

  def test_values_remaining
    values_filled = values_filled_count(@valid_puzzle_array)
    values_remaining = 81 - values_filled
    assert_equal values_remaining, @puzzle.values_remaining, "values_remaining should count the number of cells with value 0"
    @puzzle.cells.find { |cell| !cell.empty? }.reset
    assert_equal values_remaining + 1, @puzzle.values_remaining, "Should update when a cell is blanked"
  end

  def test_confirm_cell_and_update_confirmed_count
    filled_count = values_filled_count(@valid_puzzle_array)
    cell = @puzzle.cells.find { |cell| !cell.empty? }
    value_to_assign = cell.value
    cell.reset
    changed = @puzzle.update_confirmed_count
    assert changed, "Confirmed count should change after blanking a cell"
    assert_equal filled_count - 1, @puzzle.count_confirmed_values, "Should confirm cell and update count"
    cell.confirm(value_to_assign)
    assert_equal filled_count, @puzzle.count_confirmed_values, "Should confirm cell and update count"
  end

  def test_valid_and_complete_and_valid
    # skip "Need to implement with a valid puzzle setup"
    assert @puzzle.valid?, "Puzzle should be valid initially"
    solved_puzzle = Sudoku::Puzzle.new(values: Matrix[*@solved_puzzle_array])
    assert solved_puzzle.complete_and_valid?, "Solved puzzle should be valid and complete initially"
    assert solved_puzzle.valid?, "Solved puzzle should be valid"
    assert solved_puzzle.complete?, "Solved puzzle should be complete"
    cell = solved_puzzle.cell(0, 0)
    cell.value = 0
    cell.evaluate_options(true)
    refute solved_puzzle.complete_and_valid?, "Puzzle should not be complete if a cell is blank"
    refute solved_puzzle.complete?, "Puzzle should not be complete if a cell is blank"
    assert solved_puzzle.valid?, "Puzzle should still be valid if a cell is blank"
  end
end
