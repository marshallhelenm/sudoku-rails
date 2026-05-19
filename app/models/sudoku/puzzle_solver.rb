require_relative "../sudoku"

class Sudoku::PuzzleSolver
    require_relative "../sudoku"

    # Initializes the PuzzleSolver with a puzzle instance.
    # @param puzzle [Sudoku::Puzzle] the puzzle to solve
    # @param isolate [Boolean] whether to solve a duplicate of the puzzle, leaving the original puzzle unchanged
    # @param display [Boolean] whether to broadcast solving steps
    # @param print_progress [Boolean] whether to print solving steps to the console
    # @param slow_display [Boolean] whether to slow down the display of solving steps, and broadcast options updates for cells as they are changed
    def initialize(puzzle, isolate: false, display: false, print_progress: false, slow_display: false)
        unless puzzle.is_a?(Sudoku::Puzzle)
            raise ArgumentError, "puzzle must be a Sudoku::Puzzle"
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
        @display_speed = slow_display ? "medium" : "fast"
        @solve_time = nil
        @print_progress = print_progress
    end

    attr_reader :solve_time

    # Attempts to solve the Sudoku puzzle using logical strategies.
    # @return [Boolean] true if the puzzle is solved and valid, false otherwise
    def solve
        prepare_puzzle
        @solve_time = time_solving { main_solving_loop }
        @puzzle.complete_and_valid?
    end

    def prepare_puzzle
        @puzzle.reset_options
        @puzzle.cells.each do |cell|
            next if cell.value == 0
            cell.forbid_siblings(display_speed: @display_speed)
        end
        @display_speed = "slow"
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
        return true if handle_puzzle_complete
        find_families_in_groups
        return true if handle_puzzle_complete
        find_extended_families_in_groups
        return true if handle_puzzle_complete
        @puzzle.update_confirmed_count
    end

    # Confirms a cell's value, forbids that value in all siblings, optionally broadcasts the change,
    # and checks for new single option or solo option cells revealed by this change.
    # @param cell [Sudoku::Cell] The cell to confirm
    # @param value [Integer] The value to assign
    def confirm_cell(cell, value)
        print_to_console { print "⭐️" }
        cell.confirm(value)
        Sudoku.broadcast_cell(cell, display: @display, display_speed: @display_speed)
        find_sibling_fruit(cell)
    end

    # -- low hanging fruit strategies --

    def low_hanging_fruit
        # keep looking for cells with only one option and groups where a value can only go in one cell until there are no more to find
        still_searching = true
        until !still_searching do
            still_searching = find_cells_that_can_only_be_one_value || find_groups_where_only_one_cell_can_be_a_given_value
        end
    end

    # finds low hanging fruit among a cell's siblings
    def find_sibling_fruit(cell)
        groups = cell.groups
        # check siblings in each group for low hanging fruit
        find_cells_that_can_only_be_one_value(groups) || find_groups_where_only_one_cell_can_be_a_given_value(groups)
    end

    # Finds and fills cells that have only one possible value.
    # @return [Boolean] true if any cell was filled, false otherwise
    def find_cells_that_can_only_be_one_value(groups = nil)
        found_new = false
        groups ||= @puzzle.groups
        groups.each do |group|
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
    def find_groups_where_only_one_cell_can_be_a_given_value(groups = nil)
        groups ||= @puzzle.groups
        # check each row, column, and block to see if only one of its cells can be N
        found_new = false
        groups.each do |group|
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

    # -- Family strategies --

    # A family is a group of 2-3 cells within one group (row, column, or block) that are the only possible locations for a given value.
    # For example, if only 2 cells in a row can be a 5, those cells are a family for the value 5.
    # If the group we started with is a column or row, and if those 2 cells fall within the same block, then no other cell in that block can be a 5.
    # If the group we started with is a block, and if those 2 cells fall in the same row or column, then no other cell in that row or column can be a 5.

    def find_families_in_group(group)
        raise ArgumentError, "group must be a Group" unless group.is_a?(Sudoku::Group)
        invalid_group = false
        families = {}
        group.remaining_values.each do |num|
            family = []
            group.cells.each do |cell|
                next if cell.value != 0
                family << cell.coordinates if cell.options_include?(num)
                break if family.length > 3 # if there are more than 3 cells that can be this value, it's not a useful family
            end
            if family.length == 1
                # if there's only one cell that can be this value, confirm it and move on to the next value
                cell = group.find_cell_by_coordinates(family.first)
                confirm_cell(cell, num)
                next
            elsif family.length == 0 && group.remaining_values.include?(num)
                # if there are no cells that can be this value, there's a problem with the puzzle
                invalid_group = true
                break
            elsif family.length == 2 || family.length == 3
                # if there are 2 or 3 cells that can be this value, it's a family, save it for later processing
                families[num] = family
            else
                # if there are more than 3 cells that can be this value, it's not a useful family, move on to the next value
                next
            end
        end
        return false if invalid_group
        families
    end

    def forbid_other_cells_in_group_for_family(value: nil, values: [], family:, group:)
      if group.is_a?(Sudoku::Row) || group.is_a?(Sudoku::Column)
        forbid_other_cells_in_vector_for_family(value: value, values: values, family: family)
      elsif group.is_a?(Sudoku::Block)
        forbid_other_cells_in_block_for_family(value: value, values: values, family: family)
      else
        raise ArgumentError, "group must be a Sudoku::Row, Sudoku::Column, or Sudoku::Block"
      end
    end

    def forbid_other_cells_in_block_for_family(value: nil, values: [], family:)
        # if all cells in the family fall within the same block, then no other cells in the block can have that value
        return false if family.map { |coordinates| Sudoku::Cell.block_coordinates_for(coordinates.first, coordinates.last) }.uniq.length > 1
        #
        block_coordinates = Sudoku::Cell.block_coordinates_for(family.first.first, family.first.last)
        block = @puzzle.block(block_coordinates.first, block_coordinates.last)

        block.cells.each do |cell|
            next if family.include?(cell.coordinates) || cell.value != 0
            if value.present?
                cell.forbid(value, display_speed: @display_speed, print_progress: @print_progress)
            elsif values.present?
                cell.forbid_multiple(values, display_speed: @display_speed, print_progress: @print_progress)
            else
                raise ArgumentError, "Must provide either a single value or an array of values to forbid"
            end
        end
        true
    end

    def forbid_other_cells_in_vector_for_family(value: nil, values: [], family:)
        # if all cells in the family fall within the same row or column, then no other cells in that row or column can have that value
        cis = Set.new
        cjs = Set.new
        family.each do |coordinates|
            cis << coordinates.first
            cjs << coordinates.last
        end

        if cis.length == 1
            row_number = cis.first
            @puzzle.row(row_number).cells.each do |cell|
                next if family.include?(cell.coordinates) || cell.value != 0
                if value.present?
                    cell.forbid(value, display_speed: @display_speed, print_progress: @print_progress)
                elsif values.present?
                    cell.forbid_multiple(values, display_speed: @display_speed, print_progress: @print_progress)
                else
                    raise ArgumentError, "Must provide either a single value or an array of values to forbid"
                end
            end
            true
        elsif cjs.length == 1
            column_number = cjs.first
            @puzzle.column(column_number).cells.each do |cell|
                next if family.include?(cell.coordinates) || cell.value != 0
                if value.present?
                    cell.forbid(value, display_speed: @display_speed, print_progress: @print_progress)
                elsif values.present?
                    cell.forbid_multiple(values, display_speed: @display_speed, print_progress: @print_progress)
                else
                    raise ArgumentError, "Must provide either a single value or an array of values to forbid"
                end
            end
            true
        else
            # if the family doesn't fall within a single row or column, we can't apply any additional logic based on it
            false
        end
    end

    def find_families_in_groups
        @puzzle.groups.each do |group|
            break if @puzzle.complete?
            # check each group for a value that can only appear in one of two or three cells
            families = find_families_in_group(group)
            next if families == false || families.empty?
            # if we find any, forbid that value in any other cell in the group that isn't part of the family, then check for any new low hanging fruit that may have been revealed by that
            families.each do |value, family|
                forbid_other_cells_in_group_for_family(value: value, family: family, group: group)
            end
            low_hanging_fruit
        end
    end

    # Finds and processes extended families of cells that can only contain certain combinations of values. Like normal families, but instead of one value, could be several.
    # for example, only 2 cells can be a [1,2]
    # or only 3 cells can be a [4,5,6]
    # this could look like [[1,2,3], [1,2,3], [1,2,3]] or [[1,3], [1,2], [1,2,3]]
    # only goes up to size 5 because any higher and you're better off using other elimination strategies
    def find_extended_families_in_groups
        (2..6).each do |size|
            break if @puzzle.complete?
            @puzzle.groups.each do |group|
                # look for a set of numbers of size n where n cells can only contain any of those numbers
                remaining_values = group.remaining_values
                next if remaining_values.length <= (size + 1) # if there aren't at least size+1 remaining possible values for the group, we won't find any useful families of this size, so skip to the next group

                number_groupings = remaining_values.to_a.combination(size).to_a # get all combinations of possible values of the current size

                confirmed_sets = {} # key is number combination, value is array of cell coordinates that can only be those numbers

                number_groupings.each_with_index do |number_options|
                    fam = find_extended_family_in_group(group, number_options)
                    confirmed_sets[number_options] = fam if fam.present?
                end

                confirmed_sets.each do |number_options, family|
                    # for each confirmed family, forbid those numbers in any cells in the group that aren't part of the family
                    forbid_other_cells_in_group_for_family(values: number_options, family: family, group: group)
                end
                low_hanging_fruit
            end
        end
    end

    def cell_can_be_part_of_extended_family?(cell, number_options)
        (cell.options - number_options).empty?
    end

    def find_extended_family_in_group(group, number_options)
        possible_cells = []
        group.cells.each do |cell|
            next if cell.value != 0
            possible_cells << cell.coordinates if cell_can_be_part_of_extended_family?(cell, number_options)
            break if possible_cells.length > number_options.length # if there are more possible cells than the size of the set, it can't be a valid set
        end
        possible_cells.length == number_options.length ? possible_cells : nil
    end

    private

    def print_to_console
        return unless @print_progress
        yield
    end

    def handle_puzzle_complete
        if @puzzle.complete?
            @display_speed = "fast"
            return true
        end
        false
    end
end
