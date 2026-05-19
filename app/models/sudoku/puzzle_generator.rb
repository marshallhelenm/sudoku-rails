require_relative "sudoku"
require "matrix"
require_relative "../../helpers/sudoku_helper"

class Sudoku::PuzzleGenerator
    include SudokuHelper

    def initialize(print_progress: false)
        @puzzles = Sudoku.load_puzzles || {
            "easy" => [],
            "medium" => [],
            "hard" => []
        }
        @failed_completion_count = 0
        @failed_reduction_count = 0
        @created_puzzles_count = 0
        @failed_puzzles = []
        @print_progress = print_progress
        @difficulty = "medium"
    end

    attr_accessor :puzzles
    attr_accessor :failed_puzzles
    attr_accessor :failed_completion_count
    attr_accessor :failed_reduction_count


    def write_puzzles_to_json
        data = {
            "easy" => @puzzles["easy"]&.map { |p| p.values_array },
            "medium" => @puzzles["medium"]&.map { |p| p.values_array },
            "hard" => @puzzles["hard"]&.map { |p| p.values_array }
        }
        json_data = JSON.generate(data)
        file_path = Rails.root.join("app/assets/puzzle_matrices.json")
        File.open(file_path, "w") do |file|
            file.write(json_data)
        end
    end

    # Generate n puzzles and save them to a JSON file as arrays of arrays of values (no options or other metadata). This is used to generate the puzzle_matrices.json file that the frontend uses to display puzzles.
    def generate_puzzles_to_json(n, difficulty: "medium")
        @difficulty = difficulty
        generate_puzzles(n, difficulty: difficulty)
        write_puzzles_to_json
    end

    # Generate n puzzles and return them as Puzzle objects with all metadata (cells, options, groups, etc) intact.
    def generate_puzzles(n, difficulty: "medium")
        byebug
        @difficulty = difficulty.to_s
        puts "Generating #{n} #{@difficulty} puzzles..."
        puts "******************************************"
        puts ""
        reset_counts
        attempts = 0
        until @created_puzzles_count == n || attempts == n * 2 do
            puzzle = generate_solvable_puzzle(difficulty: difficulty)
            if puzzle
                if !@puzzles.has_key?(difficulty)
                    @puzzles[difficulty] = []
                end
                @puzzles[difficulty] << puzzle
                @created_puzzles_count += 1
                puts "#{@created_puzzles_count} puzzles created"
                puts "******************************************"
            end
            attempts += 1
        end
        byebug
        print_counts
        puts "#{@created_puzzles_count} Puzzles created!"
        @puzzles
    end

    # Generate a single solvable puzzle
    def generate_solvable_puzzle(difficulty: "medium")
        # start by generating a completed puzzle
        completed_puzzle = generate_completed_puzzle
        return false unless completed_puzzle
        reduced_puzzle = nil
        # then try to reduce it to a puzzle with a unique solution and the target number of confirmed values based on the difficulty level. If we fail to reduce it, start over with a new completed puzzle.
        num_confirmed_values =
            case @difficulty
            when "easy"
                40
            when "medium"
                32
            when "hard"
                25
            else
                30
            end
        5.times do
            reduced_puzzle = reduce_puzzle(completed_puzzle, num_confirmed_values)
            break if reduced_puzzle
        end
        write_puzzles_to_json if reduced_puzzle
        reduced_puzzle
    end

    # Generate a completed puzzle matrix by filling in values iteratively and using the solver to evaluate options. If we get stuck, start over.
    def generate_completed_puzzle
        puts "Building completed matrix"

        # Start with an empty puzzle and fill the first row with a random permutation of 1-9
        @working_puzzle = Sudoku::Puzzle.new
        arr = randomize(Sudoku::OPTIONS_RANGE)
        @working_puzzle.row(0).cells.each do |cell|
            value = arr.pop()
            cell.confirm(value)
        end
        print_to_console { print "⭐️" }

        # Evaluate the puzzle with the solver to fill in any cells that can be confirmed based on the initial row values.
        Sudoku::PuzzleSolver.new(@working_puzzle, print_progress: @print_progress).solve
        value_count = @working_puzzle.confirmed_count

        # Iteratively fill in values using the solver until the puzzle is complete or we get stuck
        n = 0
        passes_with_no_new_values = 0
        until @working_puzzle.complete_and_valid? || n == 50 do
            n += 1
            values_found = 0

            # Start with the groups that have the fewest remaining values, and try to confirm values in those cells
            groups = sort_groups_by_remaining_values(@working_puzzle)

            groups.each do |group|
                found_value = false
                # sort the cells in the group by fewest options to try to confirm values in those cells first
                group.cells.sort_by { |cell| cell.options.length }.each do |cell|
                    next unless cell.empty? # Skip already confirmed cells
                    cached_puzzle = @working_puzzle.duplicate # Cache the current state of the puzzle before trying to fill the cell

                    # Try each of the cell's options and use the solver to evaluate the resulting puzzle.
                    randomize(cell.options).each do |value|
                        cell.confirm(value)
                        Sudoku::PuzzleSolver.new(@working_puzzle, print_progress: @print_progress).solve
                        if @working_puzzle.valid?
                            values_found = @working_puzzle.confirmed_count
                            values_found += 1
                            # If the puzzle is still valid, break out of the loops to re-sort the groups
                            found_value = true
                            break
                        else
                            # If the puzzle is invalid, revert to the cached state and try the next option
                            @working_puzzle = cached_puzzle.duplicate
                        end
                    end
                    break if found_value # If we found a value for this cell, break out of the
                end
                break if found_value
            end

            if values_found == 0 # If we went through all the groups and couldn't confirm any new values, we're stuck. Abandon this puzzle.
                passes_with_no_new_values += 1
                @working_puzzle.bust_info_cache
                @working_puzzle.reevaluate_all_options
                byebug if @working_puzzle.valid? && !@working_puzzle.complete?
                print_to_console { puts "\nNo new values found in this pass. Stuck? #{passes_with_no_new_values >= 3 ? "Yes" : "No"}" }
                break if passes_with_no_new_values >= 3
            else
                passes_with_no_new_values = 0
            end
        end

        print_to_console { @working_puzzle.print_values }
        if @working_puzzle.complete_and_valid?
            print_to_console { puts "" }
            print_to_console { puts "🎉 Successfully made completed puzzle!" }
            @working_puzzle
        else
            print_to_console { puts "" }
            print_to_console { puts "❌ Failed to make completed matrix. Filled in #{value_count} values before getting stuck." }
            @failed_puzzles << @working_puzzle.duplicate
            @failed_completion_count += 1
            false
        end
    end

    # Try to reduce a completed puzzle matrix down to a puzzle with the given number of confirmed values by blanking cells and using the solver to check if the puzzle is still solvable. If we get stuck, start over.
    def reduce_puzzle(puzzle, num)
        completed_puzzle = puzzle
        print_to_console { puts "Reducing puzzle to #{num} confirmed values..." }
        working_puzzle =  puzzle.duplicate
        reduced_puzzle = nil
        value_count = working_puzzle.confirmed_count

        n = 1
        passes_with_no_new_blanks = 0
        until working_puzzle.confirmed_count == num || n == 50
            n += 1
            value_count = working_puzzle.confirmed_count
            # sort groups by fewest remaining values and try to blank cells in those groups first, since they're more likely to yield a solvable puzzle when blanked.
            groups = sort_groups_by_remaining_values(working_puzzle)
            groups.each do |group|
                blanked_cell = false
                randomize(group.cells).each do |cell|
                    next if cell.empty? # Skip already blank cells
                    cached_puzzle = working_puzzle.duplicate # Cache the current state of the puzzle before trying to blank the cell
                    working_puzzle.cell(cell.ci, cell.cj).reset
                    success = Sudoku::PuzzleSolver.new(working_puzzle, isolate: true).solve
                    if success
                        # if the puzzle is still solvable, keep the cell blank and break out of the loop to re-sort the groups and try blanking other cells.
                        print_to_console { print "✅" }
                        blanked_cell = true
                        break # break out of the loop to re-sort the groups and try blanking other cells
                    else
                        # if the puzzle is unsolvable, revert to the cached state and try blanking the next cell.
                        print_to_console { print "❌" }
                        working_puzzle = cached_puzzle.duplicate
                    end
                end
                break if blanked_cell # If we successfully blanked a cell in this group, break and re-sort the groups based on remaining values.
            end
            if value_count == working_puzzle.confirmed_count # If we went through all the groups and couldn't blank any new cells, we're stuck. Abandon this reduction attempt.
                passes_with_no_new_blanks += 1
                working_puzzle.bust_info_cache
                working_puzzle.reevaluate_all_options
                print_to_console { puts "\nNo new cells blanked in this pass. Stuck? #{passes_with_no_new_blanks >= 3 ? "Yes" : "No"}" }
                break if passes_with_no_new_blanks >= 3
            else
                passes_with_no_new_blanks = 0
            end
        end
        if working_puzzle.confirmed_count == num
            # we successfully reduced to the target number of confirmed values, save the reduced puzzle and break out of the loop.
            print_to_console { puts "\n🎉 Reduced puzzle successfully" }
            reduced_puzzle = working_puzzle.duplicate
            reduced_puzzle
        else
            # we failed to reduce to the target number of confirmed values, increment the failed reduction count and try again with a fresh copy of the completed puzzle. If we got stuck, increment the stuck reduction count as well.
            print_to_console { puts "❌ Failed to reduce puzzle to target confirmed count. Reduced to #{value_count} values before getting stuck." }
            print_to_console { working_puzzle.print_values }
            @failed_reduction_count += 1
            working_puzzle = completed_puzzle.duplicate
            false
        end
    end

    # -- utility methods --

    def reset_counts
        @created_puzzles_count = 0
        @failed_completion_count = 0
        @failed_reduction_count = 0
    end

    def print_counts
        puts "Created solvable puzzles: #{@created_puzzles_count}"
        puts "Failed completions: #{@failed_completion_count}"
        puts "Failed reductions: #{@failed_reduction_count}"
    end

    def sort_groups_by_remaining_values(puzzle)
        puzzle.groups.sort_by { |g| g.remaining_values.length }
    end

    def print_to_console
        return unless @print_progress
        yield
    end
end
