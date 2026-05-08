##
# PuzzleMatrix represents a 9x9 Sudoku grid and provides methods for manipulating and querying the puzzle state.
#
# Attributes:
#   matrix        - Matrix of Cell objects representing the puzzle grid
#
# Constants:
#   VALUE_RANGE   - Allowed cell values (0-9)
#   OPTIONS_RANGE - Allowed options for a cell (1-9)
#   ZERO_RANGE    - Allowed indices for rows/columns (0-8)
#
# Methods:
#   initialize(values:, options:, source_matrix:) - Create a new puzzle matrix
#   duplicate                                    - Return a deep copy of the puzzle
#   reset_options                                - Reset all cell options
#   cell(i, j)                                   - Get the cell at (i, j)
#   row(ci), column(cj)                          - Get a row or column as a Line
#   block(ci, cj), block_from_cell(cell)         - Get a block (3x3 region)
#   groups, vectors, blocks                      - Get all logical groups
#   count_confirmed_values, count_blank_cells    - Count filled/empty cells
#   values_matrix, values_array                  - Get values as matrix/array
#   options_matrix, options_array                - Get options as matrix/array
#   siblings_of(cell)                            - Get all siblings of a cell

class PuzzleMatrix
    require "matrix"
    require_relative "cell"
    require_relative "group"
    require_relative "line"
    require_relative "block"
    require_relative "sudoku"

    VALUE_RANGE = Sudoku::VALUE_RANGE
    OPTIONS_RANGE = Sudoku::OPTIONS_RANGE
    ZERO_RANGE = Sudoku::ZERO_RANGE

    # Initialize a PuzzleMatrix with optional values, options, or a source matrix.
    # Raises ArgumentError if input types are invalid.
    def initialize(values: nil, options: nil, source_matrix: nil)
        # Validate source_matrix
        if source_matrix && !source_matrix.is_a?(PuzzleMatrix)
            raise ArgumentError, "source_matrix must be a PuzzleMatrix"
        end

        # Validate values
        if values
            unless values.is_a?(Matrix) && values.all? { |v| v.is_a?(Integer) }
                raise ArgumentError, "values must be a Matrix of integers"
            end
        end

        # Validate options
        if options
            unless options.is_a?(Matrix) && options.all? { |v| v.is_a?(Array) && v.all? { |i| i.is_a?(Integer) } }
                raise ArgumentError, "options must be a Matrix of arrays of integers"
            end
        end

        @matrix = Matrix.build(9) { |ci, cj| Cell.new(value: 0, ci: ci, cj: cj) }

        if source_matrix.present?
          @matrix.each_with_index do |cell, ci, cj|
            source_cell = source_matrix.cell(ci, cj)
            cell.value = source_cell.value
            cell.options = source_cell.options.dup
          end
        else
            if values != nil
                values.each_with_index do |val, ci, cj|
                    cell = @matrix[ci, cj]
                    cell.value = val
                    cell.options = options[ci, cj].dup if options.present?
                end
            end
        end
    end

    attr_reader :matrix

    # Return a deep copy of the puzzle matrix
    def duplicate
        PuzzleMatrix.new(source_matrix: self)
    end

    # Reset all cell options: filled cells get [], empty cells get full range
    def reset_options
        @matrix.each do |cell|
            if cell.value != 0
                cell.options = []
            else
                cell.options = VALUE_RANGE
            end
        end
    end

    # Get the cell at (i, j)
    def cell(i, j)
        @matrix[i, j]
    end

    # Return the matrix of cells
    def cells
        @matrix
    end

    # Get a row as a Line object
    def row(ci)
        Line.new(@matrix.row(ci))
    end

    # Get an array of Line objects for the given range of rows
    def rows(range = ZERO_RANGE)
        arr = []
        range.each do |num|
            arr << row(num)
        end
        arr
    end

    # Get a column as a Line object
    def column(cj)
        Line.new(@matrix.column(cj))
    end

    # Get an array of Line objects for all columns
    def columns
        arr = []
        ZERO_RANGE.each do |num|
            arr << column(num)
        end
        arr
    end

    # Get all row and column Line objects
    def vectors
        arr = []
        ZERO_RANGE.each do |num|
            arr << row(num)
            arr << column(num)
        end
        arr
    end

    # Get the Block object for the given block indices
    def block(ci, cj)
        Block.new(self, ci, cj)
    end

    # Returns the Block for the given cell using integer division for block indices
    def block_from_cell(cell)
        block_row = cell.ci / 3
        block_col = cell.cj / 3
        Block.new(self, block_row, block_col)
    end

    # Get all Block objects in the puzzle
    def blocks
        arr = [
            [ 0, 0 ], [ 0, 1 ], [ 0, 2 ],
            [ 1, 0 ], [ 1, 1 ], [ 1, 2 ],
            [ 2, 0 ], [ 2, 1 ], [ 2, 2 ]
        ].map do |coords|
            block(coords[0], coords[1])
        end
        arr
    end

    # Get all logical groups (rows, columns, and blocks)
    def groups
        vectors + blocks
    end

    # Count the number of cells with a confirmed (nonzero) value
    def count_confirmed_values
        @matrix.count { |cell| !cell.empty? }
    end

    # Count the number of blank (zero) cells
    def count_blank_cells
        @matrix.count { |cell| cell.empty? }
    end

    # Return a matrix of cell values
    def values_matrix
        @matrix.map { |cell| cell.value }
    end

    # Return an array of cell values
    def values_array
        values_matrix.to_a
    end

    # Return a matrix of cell options
    def options_matrix
        @matrix.map { |cell| cell.options }
    end

    # Return an array of cell options
    def options_array
        options_matrix.to_a
    end

    # Return all sibling cells (same row, column, or block) for a given cell
    def siblings_of(cell)
        siblings = []
        siblings += row(cell.ci).cells
        siblings += column(cell.cj).cells
        siblings += block_from_cell(cell).cells
        siblings.uniq!
        siblings.delete(cell)
        siblings
    end
end
