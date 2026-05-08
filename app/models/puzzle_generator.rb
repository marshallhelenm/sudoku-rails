class PuzzleGenerator
    require_relative "sudoku"
    require "matrix"

    PUZZLE_MATRICES = Sudoku::PUZZLES

    def initialize
        @puzzle_matrices = []
        @failed_completion_count = 0
        @stuck_completion_count = 0
        @failed_reduction_count = 0
        @stuck_reduction_count = 0
        @created_matrices_count = 0
    end

    attr_accessor :puzzle_matrices

    def self.load_puzzles
        puzzles = []
        data = JSON.parse(PUZZLES)
        data.each do |puzzle_data|
            puzzle = Puzzle.new(values: Matrix[*puzzle_data])
            puzzles << puzzle
        end
        puzzles
    end

    def self.load_puzzle_matrices
        data = JSON.parse(PUZZLE_MATRICES)
        data.map do |matrix_data|
            cells = matrix_data.map do |cell_value|
                Cell.new(value: cell_value)
            end
            Puzzle.new(values: Matrix[*cells])
        end
        @puzzle_matrices = data
    end

    def generate_puzzles_to_json(n)
        puzzles = generate_puzzle_matrices(n)
        data = puzzles.map do |matrix|
            matrix.cells.map do |cell|
                cell.value
            end.to_a
        end
        json_data = JSON.generate(data)
        file_path = Rails.root.join("app/assets/puzzle_matrices.json")
        File.open(file_path, "w") do |file|
            file.write(json_data)
        end
    end

    def generate_puzzle
        if completed_matrix = generate_completed_puzzle
                if reduced_matrix = reduce_matrix(completed_matrix, 40)
                Puzzle.new(values: reduced_matrix.cells).print_puzzle_information
                reduced_matrix
                else
                false
                end
        else
            false
        end
    end

    def generate_puzzle_matrices(n)
        reset_counts
        attempts = 0
        until @puzzle_matrices.count == n || attempts == n*2 do
            matrix = generate_puzzle
            if matrix
                @puzzle_matrices << matrix
                puts "#{@puzzle_matrices.count} matrices created"
                puts "******************************************"
                puts ""
            end
            attempts += 1
        end
        puts "Completed matrices: #{@created_matrices_count}"
        puts "Failed completions: #{@failed_completion_count}"
        puts "Stuck completions: #{@stuck_completion_count}"
        puts "Failed reductions: #{@failed_reduction_count}"
        puts "Stuck reductions: #{@stuck_reduction_count}"
        @puzzle_matrices
    end

    def generate_puzzles(n)
        puts "Generating #{n} puzzles"
        generate_puzzle_matrices(n)
        puzzles = @puzzle_matrices.map { |matrix| Puzzle.new(values: matrix) }
        puts "Puzzles created!"
        puzzles
    end

    def generate_completed_puzzle(print_completed: false)
        @completion_stuck = false
        puts "Building completed matrix"
        @working_matrix = Puzzle.new
        @working_puzzle = Puzzle.new(values: @working_matrix)
        arr = randomize(range)
        @working_matrix.row(0).cells.each do |cell|
            cell.value = arr.pop()
            @working_puzzle.update_cell(cell)
        end
        PuzzleSolver.new(@working_puzzle).evaluate_initial_options
        value_count = @working_matrix.count_confirmed_values
        n = 1
        until @working_puzzle.complete_and_valid? || n == 5 do
            groups = @working_matrix.rows.sort_by { |g|g.remaining_values.length }
            groups.each do |group|
                next if group.remaining_values == 0
                group.empty_cells.each do |cell|
                    next if cell.value != 0
                    cached_matrix = @working_matrix.duplicate
                    options = randomize(cell.options)
                    options.each do |value|
                        cell.value = value
                        cell.options = []
                        @working_puzzle.update_cell(cell)
                        PuzzleSolver.new(@working_puzzle).solve
                        if !@working_puzzle.valid?
                            @working_matrix = cached_matrix.duplicate
                        end
                        break if @working_puzzle.valid?
                    end
                    new_value_count = @working_matrix.count_confirmed_values
                    if new_value_count == value_count
                        @completion_stuck = true
                        increment_stuck_completion_count
                    end
                    value_count = new_value_count
                    print "."
                    break if !@working_puzzle.valid? || @completion_stuck
                end
                break if @completion_stuck
            end
            break if @completion_stuck
        end
        if @working_puzzle.complete_and_valid? && !@completion_stuck
            puts ""
            puts "successfully made completed matrix"
            @working_matrix.print_puzzle if print_completed == true
            @working_matrix
        else
            puts ""
            puts "failed to make completed matrix #{'- Got stuck' if @completion_stuck}"
            increment_failed_completion_count
            false
        end
    end

    def reduce_matrix(matrix, num)
        @stuck_reduction = false
        puts "reducing matrix"
        @working_matrix = matrix.duplicate
        @working_puzzle = Puzzle.new(values: @working_matrix)
        @reduced_matrix = nil
        n = 0
        value_count = @working_matrix.count_confirmed_values
        100.times do
            until @working_matrix.count_confirmed_values == num || n == 5
                n += 1
                randomize(@working_matrix.cells).each_with_index do |cell, index|
                    next if cell.empty?
                    cached_matrix = @working_matrix.duplicate
                    @working_matrix.cell(cell.ci, cell.cj).reset
                    success = PuzzleSolver.new(@working_puzzle, isolate: true).solve
                    if !success
                        @working_matrix = cached_matrix.duplicate
                    end
                    new_value_count = @working_matrix.count_confirmed_values
                    if new_value_count == value_count
                        @stuck_reduction = true
                    end
                    value_count = new_value_count
                    break if new_value_count == num || @stuck_reduction
                    print "."
                end
                break if @stuck_reduction
            end
            if @working_matrix.count_confirmed_values == num
                puts ""
                puts "reduced matrix successfully"
                increment_created_matrices_count
                @reduced_matrix = @working_matrix.duplicate
                break
            else
                puts ""
                puts "failed to reduce matrix #{'- Got stuck' if @stuck_reduction}"
                increment_failed_reduction_count
                increment_stuck_reduction_count if @stuck_reduction
                @working_matrix = matrix.duplicate
                false
            end
        end
        @reduced_matrix
    end

    def print_confirmed_values(matrix)
        print " - #{matrix.count_confirmed_values}"
    end

    def increment_failed_completion_count
        @failed_completion_count += 1
    end

    def increment_stuck_completion_count
        @stuck_completion_count += 1
    end

    def increment_failed_reduction_count
        @failed_reduction_count += 1
    end

    def increment_stuck_reduction_count
        @stuck_reduction_count += 1
    end

    def increment_created_matrices_count
        @created_matrices_count += 1
    end

    def reset_counts
        @created_matrices_count = 0
        @failed_completion_count = 0
        @stuck_completion_count = 0
        @failed_reduction_count = 0
        @stuck_reduction_count = 0
    end
end
