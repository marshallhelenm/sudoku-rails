# frozen_string_literal: true

require "minitest/autorun"
require "matrix"
require "byebug"
require_relative "../../app/models/puzzle_matrix"
require_relative "../../app/models/cell"

class PuzzleMatrixTest < Minitest::Test
  def setup
    @values = Matrix.build(9) { |i, j| j + 1 } # Example values for testing, not a valid Sudoku puzzle
    @options = Matrix.build(9) { Array(1..9) }
    @matrix = PuzzleMatrix.new(values: @values, options: @options)
  end

  def test_initialize_valid
    assert_instance_of PuzzleMatrix, @matrix, "Should initialize a PuzzleMatrix with valid values and options"
    assert_equal 9, @matrix.matrix.row_count, "Matrix should have 9 rows"
    assert_equal 9, @matrix.matrix.column_count, "Matrix should have 9 columns"
  end

  def test_initialize_invalid_values
    bad_values = Matrix.build(9) { "a" }
    assert_raises(ArgumentError, "Should raise error for non-integer values") { PuzzleMatrix.new(values: bad_values) }
  end

  def test_initialize_invalid_options
    bad_options = Matrix.build(9) { [ 1, "a", 3 ] }
    assert_raises(ArgumentError, "Should raise error for non-integer options") { PuzzleMatrix.new(values: @values, options: bad_options) }
  end

  def test_duplicate
    dup = @matrix.duplicate
    refute_same @matrix, dup, "Duplicate should return a new PuzzleMatrix instance"
    assert_equal @matrix.values_array, dup.values_array, "Duplicate should have the same values"
  end

  def test_cell_and_cells
    cell = @matrix.cell(0, 0)
    assert_instance_of Cell, cell, "cell(i, j) should return a Cell"
    assert_equal 0, cell.ci
    assert_equal 0, cell.cj
    assert_equal @matrix.matrix, @matrix.cells, "cells should return the matrix"
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
    assert_equal 81, @matrix.count_confirmed_values, "All cells should be confirmed (nonzero) except for zeros"
    @matrix.cell(0, 0).value = 0
    assert_equal 80, @matrix.count_confirmed_values, "Confirmed values should decrease when a cell is set to 0"
    assert_equal 1, @matrix.count_blank_cells, "Blank cells should increase when a cell is set to 0"
  end

  def test_values_and_options_matrix_array
    assert_equal @values.to_a.flatten, @matrix.values_array.flatten, "values_array should match the input values"
    assert_equal Array.new(81, (1..9).to_a), @matrix.options_array.flatten(1), "options_array should match the input options"
  end

  def test_siblings_of
    cell = @matrix.cell(0, 0)
    siblings = @matrix.siblings_of(cell)
    assert siblings.all? { |sib| sib.is_a?(Cell) }, "All siblings should be Cell instances"
    refute_includes siblings, cell, "Siblings should not include the cell itself"
  end
end
