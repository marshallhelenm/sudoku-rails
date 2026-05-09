class PuzzleGenerator
    include ApplicationHelper
    require_relative "sudoku"
    require "matrix"

    def initialize
        @puzzles = Sudoku.load_puzzles || []
        @failed_completion_count = 0
        @failed_reduction_count = 0
        @created_puzzles_count = 0
        @failed_puzzles = []
    end

    attr_accessor :puzzles
    attr_accessor :failed_puzzles
    attr_accessor :failed_completion_count
    attr_accessor :failed_reduction_count

    def generate_puzzles_to_json(n)
        puzzles = generate_puzzles(n)
        data = puzzles.map { |puzzle| puzzle.values_array }
        json_data = JSON.generate(data)
        file_path = Rails.root.join("app/assets/puzzle_matrices.json")
        File.open(file_path, "w") do |file|
            file.write(json_data)
        end
    end

    def generate_solvable_puzzle
        completed_puzzle = generate_completed_puzzle
        return false unless completed_puzzle
        reduced_puzzle = reduce_puzzle(completed_puzzle, 30)
        reduced_puzzle
    end

    def generate_puzzles(n, total_attempts = nil)
        puts "Generating #{n} puzzles"
        reset_counts
        attempts = 0
        total_attempts ||= n * 2
        until @puzzles.count == n || attempts == total_attempts do
            puzzle = generate_solvable_puzzle
            if puzzle
                @puzzles << puzzle
                @created_puzzles_count += 1
                puts "#{@puzzles.count} puzzles created"
                puts "******************************************"
            end
            attempts += 1
        end
        print_counts
        puts "#{@puzzles.count} Puzzles created!"
        @puzzles
    end

    # Generate a completed puzzle matrix by filling in values iteratively and using the solver to evaluate options. If we get stuck, start over.
    def generate_completed_puzzle
        @completion_stuck = false
        puts "Building completed matrix"
        # Start with an empty puzzle and fill the first block with a random permutation of 1-9
        @working_puzzle = Puzzle.new
        arr = randomize(Sudoku::OPTIONS_RANGE)
        @working_puzzle.blocks_array.first.cells.each do |cell|
            value = arr.pop()
            @working_puzzle.confirm_cell(value, cell.ci, cell.cj)
            print "."
        end

        # Evaluate initial options for all cells based on the first block and count confirmed values
        @working_puzzle.evaluate_initial_options
        value_count = @working_puzzle.count_confirmed_values

        # Iteratively fill in values using the solver until the puzzle is complete or we get stuck


        n = 1
        passes_with_no_new_values = 0
        until @working_puzzle.complete_and_valid? || n == 50 do
            n += 1
            value_count = @working_puzzle.count_confirmed_values

            # Start with the groups that have the fewest remaining values, and try to confirm values in those cells
            groups = @working_puzzle.groups.select { |g| g.incomplete? }.sort_by { |g|g.remaining_values.length }

            groups.each do |group|
                found_value = false

                group.cells.each do |cell|
                    next unless cell.empty? # Skip already confirmed cells
                    cached_puzzle = @working_puzzle.duplicate # Cache the current state of the puzzle before trying to fill the cell

                    randomize(cell.options).each do |value|
                        # Try each of the cell's options and use the solver to evaluate the resulting puzzle.
                        @working_puzzle.confirm_cell(value, cell.ci, cell.cj)
                        PuzzleSolver.new(@working_puzzle).solve
                        if @working_puzzle.valid?
                            # If the puzzle is still valid, break out of the options loop and continue filling other cells
                            print "."
                            found_value = true
                            break
                        else
                            # If the puzzle is invalid, revert to the cached state and try the next option
                            # byebug unless @stop
                            @working_puzzle = cached_puzzle.duplicate
                        end
                    end
                    if found_value
                        print "."
                        break # If we found a value for this cell, break out of the empty_cells loop to re-sort the groups.
                    else
                        print "x"
                        next # Otherwise, try the next cell in this group.
                    end
                end
                found_value ? break : next # If we found a value in this group, break and re-sort the groups based on remaining values. Otherwise, try the next group.
            end
            if value_count == @working_puzzle.count_confirmed_values # If we went through all the groups and couldn't confirm any new values, we're stuck. Abandon this puzzle.
                passes_with_no_new_values += 1
                @working_puzzle.reevaluate_all_options
                puts "\nNo new values found in this pass. Stuck? #{passes_with_no_new_values >= 5}"
                break if passes_with_no_new_values >= 5
            else
                passes_with_no_new_values = 0
            end
        end

        if @working_puzzle.complete_and_valid?
            puts "\n successfully made completed matrix"
            @working_puzzle
        else
            puts "\n failed to make completed matrix"
            @failed_puzzles << @working_puzzle.duplicate
            increment_failed_completion_count
            false
        end
    end

    # Try to reduce a completed puzzle matrix down to a puzzle with the given number of confirmed values by blanking cells and using the solver to check if the puzzle is still solvable. If we get stuck, start over.
    def reduce_puzzle(puzzle, num)
        @stuck_reduction = false
        puts "reducing puzzle to #{num} confirmed values"
        @working_puzzle =  puzzle.duplicate
        @reduced_puzzle = nil
        n = 0
        value_count = @working_puzzle.count_confirmed_values

        # Randomly blank cells and check if the puzzle is still solvable until we reach the target number of confirmed values or get stuck
        10.times do
            until @working_puzzle.count_confirmed_values == num || n == 5
                n += 1
                value_count = @working_puzzle.count_confirmed_values
                randomize(@working_puzzle.cells.select { |cell| !cell.empty? }).each_with_index do |cell, index|
                    cached_puzzle = @working_puzzle.duplicate # Cache the current state of the puzzle before blanking the cell

                    @working_puzzle.cell(cell.ci, cell.cj).reset

                    success = PuzzleSolver.new(@working_puzzle, isolate: true).solve
                    if success
                        print "."
                        break if @working_puzzle.count_confirmed_values == num
                    else
                        @working_puzzle = cached_puzzle.duplicate if !success
                    end
                end
                @working_puzzle.count_confirmed_values == value_count ? @stuck_reduction = true : next # If we went through all the cells and couldn't blank any new cells, we're stuck. Abandon this reduction attempt.
                break if @stuck_reduction
            end

            if @working_puzzle.count_confirmed_values == num
                # we successfully reduced to the target number of confirmed values, save the reduced puzzle and break out of the loop.
                puts "\n reduced puzzle successfully"
                increment_created_matrices_count
                @reduced_puzzle = @working_puzzle.duplicate
                break
            else
                # we failed to reduce to the target number of confirmed values, increment the failed reduction count and try again with a fresh copy of the completed puzzle. If we got stuck, increment the stuck reduction count as well.
                puts "\nfailed to reduce puzzle #{'- Got stuck' if @stuck_reduction}"
                increment_failed_reduction_count
                increment_stuck_reduction_count if @stuck_reduction
                @working_puzzle = puzzle.duplicate
                false
            end
        end
        @reduced_puzzle
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
        @created_puzzles_count += 1
    end

    def reset_counts
        @created_puzzles_count = 0
        @failed_completion_count = 0
        @stuck_completion_count = 0
        @failed_reduction_count = 0
        @stuck_reduction_count = 0
    end

    def print_counts
        puts "Completed matrices: #{@created_puzzles_count}"
        puts "Failed completions: #{@failed_completion_count}"
        puts "Stuck completions: #{@stuck_completion_count}"
        puts "Failed reductions: #{@failed_reduction_count}"
        puts "Stuck reductions: #{@stuck_reduction_count}"
    end
end
