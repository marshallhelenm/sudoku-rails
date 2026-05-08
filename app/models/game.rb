class Game < Sudoku
    def initialize(puzzle: nil)
        # validate puzzle
        if puzzle && !puzzle.is_a?(PuzzleMatrix)
            raise ArgumentError, "puzzle must be a PuzzleMatrix"
        end

        if puzzle.present?
            @puzzle_matrix = puzzle
            @confirmed_count = @puzzle_matrix.count_confirmed_values
        else
            @puzzle_matrix = PuzzleMatrix.new
            @confirmed_count = 0
        end
        @invalid = false

        @cached_matrix = @puzzle_matrix.duplicate
    end

    attr_accessor :confirmed_count
    attr_accessor :puzzle_matrix
    attr_accessor :invalid

    def optionless_cell_count
        @puzzle_matrix.cells.count do |cell|
            cell.value == 0 && cell.options.length == 0
        end
    end

    def values_remaining
        81 - @confirmed_count
    end

    def complete?
        update_values_found
        @confirmed_count == 81
    end

    def complete_and_valid?
        valid? && complete?
    end

    def puzzle_groups
        @puzzle_matrix.groups
    end

    def puzzle_vectors
        @puzzle_matrix.vectors
    end

    def reset_puzzle_matrix
        @puzzle_matrix = @cached_matrix.duplicate
    end

    def confirm_cell(value, ci, cj)
        cell = @puzzle_matrix.cell(ci, cj)
        cell.evaluate_and_assign_value(value, @puzzle_matrix)
        cell.forbid_siblings(@puzzle_matrix)
        update_values_found
    end

    def broadcast_cell(ci, cj)
        cell = @puzzle_matrix.cell(ci, cj)
        Turbo::StreamsChannel.broadcast_action_to(:cell_squares, action: :replace, target: "cell_#{cell.ci}_#{cell.cj}", partial: "sudoku/cell_square", locals: { value: cell.value, ci: cell.ci, cj: cell.cj, options: cell.options })
    end

    def update_values_found
        new_values_found = @puzzle_matrix.count_confirmed_values
        number_changed = new_values_found != @confirmed_count
        @confirmed_count = new_values_found
        number_changed
    end

    def forbid_cell_relatives(cell)
        @puzzle_matrix.row(cell.ci).forbid_value(cell.value)
        @puzzle_matrix.column(cell.cj).forbid_value(cell.value)
        @puzzle_matrix.block_from_cell(cell).forbid_value(cell.value)
    end

    def valid?
        optionless_cell_count == 0 && @puzzle_matrix.groups.all?(&:valid?)
    end
end
