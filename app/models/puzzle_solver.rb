class PuzzleSolver
    require_relative "sudoku"
    require_relative "family_handler"

    # Initializes the PuzzleSolver with a puzzle instance.
    # @param puzzle [Puzzle] the puzzle to solve
    # @param isolate [Boolean] whether to solve a duplicate of the puzzle
    # @param display [Boolean] whether to broadcast solving steps
    def initialize(puzzle, isolate: false, display: false)
        unless puzzle.is_a?(Puzzle)
            raise ArgumentError, "puzzle must be a Puzzle"
        end
        unless [ true, false ].include?(isolate)
            raise ArgumentError, "isolate must be a boolean"
        end
        unless [ true, false ].include?(display)
            raise ArgumentError, "display must be a boolean"
        end

        if isolate
            @puzzle = puzzle.duplicate
        else
            @puzzle = puzzle
        end
        @display = display
        @solve_time = nil
        @family_handler = FamilyHandler.new(self, @puzzle)
    end

    attr_reader :solve_time

    # Attempts to solve the Sudoku puzzle using logical strategies.
    # @return [Boolean] true if the puzzle is solved and valid, false otherwise
    def solve
        prepare_puzzle
        @solve_time = time_solving { main_solving_loop }
        byebug
        @puzzle.complete_and_valid?
    end

    def prepare_puzzle
        @puzzle.reset_options
        @puzzle.cells.each do |cell|
            next if cell.value == 0
            cell.forbid_siblings
        end
    end

    def time_solving
        @start_time = Time.now
        yield
        Time.now - @start_time
    end

    def main_solving_loop
        passes_with_no_progress = 0
        until finished?(passes_with_no_progress)
            progress = try_solving_strategies
            passes_with_no_progress += 1 unless progress
        end
    end

    def finished?(passes_with_no_progress)
        @puzzle.complete? || passes_with_no_progress == 3
    end

    def try_solving_strategies
        low_hanging_fruit
        return true if @puzzle.complete?
        puts "Looking for families..."
        @family_handler.find_families_in_groups
        return true if @puzzle.complete?
        puts "Looking for extended families..."
        @family_handler.find_extended_families_in_groups
        return true if @puzzle.complete?
        @puzzle.update_confirmed_count
    end

    # Confirms a cell's value, forbids that value in all siblings, optionally broadcasts the change,
    # and checks for new single option or solo option cells revealed by this change.
    # @param cell [Cell] The cell to confirm
    # @param value [Integer] The value to assign
    def confirm_cell(cell, value)
        puts "Confirming cell (#{cell.ci}, #{cell.cj}) as #{value}!"
        cell.confirm(value)
        broadcast_cell(cell.ci, cell.cj) if @display
        find_cells_that_can_only_be_one_value
        find_groups_where_only_one_cell_can_be_a_given_value
    end

    def broadcast_cell(ci, cj)
        cell = @puzzle.cell(ci, cj)
        Turbo::StreamsChannel.broadcast_action_to(:cell_squares, action: :replace, target: "cell_#{cell.ci}_#{cell.cj}", partial: "sudoku/cell_square", locals: { value: cell.value, ci: cell.ci, cj: cell.cj, options: cell.options })
    end


    # -- low hanging fruit strategies --

    def low_hanging_fruit
        # keep looking for cells with only one option and groups where a value can only go in one cell until there are no more to find
        puts "Looking for low hanging fruit..."
        still_searching = true
        until !still_searching do
            print "."
            still_searching = find_cells_that_can_only_be_one_value || find_groups_where_only_one_cell_can_be_a_given_value
        end
        puts ""
    end

    # Finds and fills cells that have only one possible value.
    # @return [Boolean] true if any cell was filled, false otherwise
    def find_cells_that_can_only_be_one_value
        found_new = false
        @puzzle.groups.each do |group|
            # do this by looking at 'blank_cells' since that is cached and won't require evaluating options for cells that are already filled, or haven't been touched since they were last looked at
            group.blank_cells.each do |cell|
                if cell.options.length == 1
                    confirm_cell(cell, cell.options.first)
                    found_new = true
                end
            end
        end
        found_new
    end

    # Finds and fills cells in groups (row, column, block) where a value can only go in one cell.
    # @return [Boolean] true if any cell was filled, false otherwise
    def find_groups_where_only_one_cell_can_be_a_given_value
        # check each row, column, and block to see if only one of its cells can be N
        found_new = false
        @puzzle.groups.each do |group|
            group.remaining_values.each do |num|
                only_possible_cell = find_only_possible_cell_for_value_in_group(group, num)
                if only_possible_cell
                    confirm_cell(@puzzle.cell(only_possible_cell.first, only_possible_cell.last), num)
                    found_new = true
                end
            end
        end
        found_new
    end

    def find_only_possible_cell_for_value_in_group(group, num)
        only_possible_cell = nil
        group.cells.each do |cell|
            next if cell.value != 0
            next unless cell.options_include?(num)
            if only_possible_cell.nil?
                # if we haven't found a possible cell for this value yet, this is the possible cell
                only_possible_cell = cell
            else
                # if we already have a possible cell, this isn't a solo option, move on to the next value
                only_possible_cell = nil
                break
            end
        end
        only_possible_cell&.coordinates
    end
end
