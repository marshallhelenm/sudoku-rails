class PuzzleSolver
    require_relative "sudoku"

    # Initializes the PuzzleSolver with a puzzle instance.
    # @param puzzle [Puzzle] the puzzle to solve
    # @param isolate [Boolean] whether to solve a duplicate of the puzzle
    # @param display [Boolean] whether to broadcast solving steps
    def initialize(puzzle, isolate: false, display: false, )
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
    end

    attr_reader :solve_time

    # Attempts to solve the Sudoku puzzle using logical strategies.
    # @return [Boolean] true if the puzzle is solved and valid, false otherwise
    def solve
        prepare_puzzle
        @solve_time = time_solving { main_solving_loop }
        @puzzle.complete_and_valid?
    end

    private

    attr_reader :puzzle, :display

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
        find_families_in_vectors
        return true if @puzzle.complete?
        find_families_in_blocks
        return true if @puzzle.complete?
        find_sets
        return true if @puzzle.complete?
        @puzzle.update_values_found if @puzzle.respond_to?(:update_values_found)
    end

    # Fills in cells with only one possible value and finds solo options in groups until no more can be found.
    def low_hanging_fruit
        # keep looking for cells with only one option and groups where a value can only go in one cell until there are no more to find
        return if @puzzle.complete?
        still_searching = true
        until !still_searching do
            found_new = find_single_option_cell
            found_new ||= find_solo_options
            still_searching = found_new
        end
    end

    # Finds and fills cells that have only one possible value.
    # @return [Boolean] true if any cell was filled, false otherwise
    def find_single_option_cell
        # find cells that only have one remaining option
        found_new = false
        still_searching = true
        until !still_searching
            @puzzle.cells.each_with_index do |cell, i, j|
                still_searching = !(i == 8 && j == 8)
                next if cell.value != 0
                next unless cell.options.length == 1

                confirm_cell(cell.options.first, i, j)
                found_new = true
                break
            end
        end
        found_new
    end

    # Finds and fills cells in groups (row, column, block) where a value can only go in one cell.
    # @return [Boolean] true if any cell was filled, false otherwise
    def find_solo_options
        # check each row, column, and block to see if only one of its cells can be N
        found_new = false
        @puzzle.groups.each do |group|
            remaining = group.remaining_values
            remaining.each do |num|
                possible_cell = nil
                group.cells.each do |cell|
                    next if cell.value != 0
                    next unless cell.options_include?(num)
                    if possible_cell.nil?
                        # if we haven't found a possible cell for this value yet, this is the possible cell
                        possible_cell = cell
                    else
                        # if we already have a possible cell, this isn't a solo option, move on to the next value
                        possible_cell = nil
                        break
                    end
                end
                next unless possible_cell && possible_cell.respond_to?(:ci) && possible_cell.respond_to?(:cj)
                confirm_cell(num, possible_cell.ci, possible_cell.cj)
                found_new = true
            end
        end
        found_new
    end

    # Finds families of cells in a group that can only contain certain values.
    # @param group [Group] the group to search
    # @return [Hash] mapping of value to families
    def find_families_in_group(group)
        raise ArgumentError, "group must be a Group" unless group.is_a?(Group)

        families = {}
        Sudoku::COORD_RANGE.each do |num|
            families[num] = []
            family = []
            group.cells.each do |cell|
                family << cell if cell.options_include?(num)
                break if family.length > 2
            end
            families[num] << family if (2..3).include?(family.length)
        end
        families
    end

    # Applies family-finding logic to all vectors (rows and columns).
    def find_families_in_vectors
        @puzzle.vectors.each do |vector|
            break if @puzzle.complete?
            # check each group for a value that can only appear in one of two or three cells
            families = find_families_in_group(vector)
            # if all cells in the family fall within the same block, then no other cells in the block can have that value
            families.each_key do |value|
                families[value].each do |family|
                    if family.collect(&:block_coordinates).uniq.length == 1
                        family[0].block.cells.each do |cell|
                            next if family.include?(cell)
                            cell.forbid(value)
                        end
                    end
                end
            end
            low_hanging_fruit
        end
    end

    # Applies family-finding logic to all blocks.
    def find_families_in_blocks
        @puzzle.blocks_array.each do |block|
            break if @puzzle.complete?
            # check each block for a value that can only appear in one of two or three cells
            families = find_families_in_group(block)
            # if all cells in the family fall within the same row or column, then no other cells in that row or column can have that value
            families.each_key do |value|
                families[value].each do |family|
                    if family.collect(&:ci).uniq.length == 1
                        family[0].row.cells.each do |cell|
                            next if family.include?(cell)
                            cell.forbid(value)
                        end
                    elsif family.collect(&:cj).uniq.length == 1
                        family[0].column.cells.each do |cell|
                            next if family.include?(cell)
                            cell.forbid(value)
                        end
                    end
                end
            end
            low_hanging_fruit
        end
    end

    # Finds and processes sets of cells that can only contain certain combinations of values.
    def find_sets
        (2..6).each do |size|
            break if @puzzle.complete?
            @puzzle.groups.each do |group|
                # look for a set of numbers of size n where n cells can only contain any of those numbers
                # for example, only 2 cells can be a [1,2]
                # or only 3 cells can be a [4,5,6]
                # this could look like [[1,2,3], [1,2,3], [1,2,3]] or [[1,3], [1,2], [1,2,3]]
                # only goes up to size 5 because any higher and you're better off using other elimination strategies
                return if @puzzle.complete?
                possible_values = group.remaining_values
                next if possible_values.length <= size
                number_groupings = possible_values.combination(size).to_a
                confirmed_sets = {} # key is index of number grouping, value is array of cells that can only be those numbers
                number_groupings.each_with_index do |number_options, index|
                    possible_cells = []
                    group.cells.each do |cell|
                        next if cell.value != 0
                        if (cell.options - number_options).empty?
                            # if all of the cell's options are in the number options, it's a possible cell for this set
                            possible_cells << cell
                        end
                        if possible_cells.length > size
                            # if there are more possible cells than the size of the set, it can't be a valid set
                            break
                        end
                    end
                    if possible_cells.length == size
                        confirmed_sets[index] = possible_cells
                    end
                end
                confirmed_sets.each do |key, set|
                    # for each confirmed set, forbid those numbers in any cells in the group that aren't part of the set
                    set_values = number_groupings[key]
                    group.cells.each do |cell|
                        next if set.include?(cell) || cell.value != 0
                        cell.forbid(set_values)
                    end
                end
                low_hanging_fruit
            end
        end
    end

    # Confirms a cell's value, forbids that value in all siblings, optionally broadcasts the change,
    # and checks for new single option or solo option cells revealed by this change.
    # @param value [Integer] The value to assign
    # @param ci [Integer] Row index
    # @param cj [Integer] Column index
    def confirm_cell(value, ci, cj)
        @puzzle.confirm_cell(value, ci, cj)
        broadcast_cell(ci, cj) if @display
        find_single_option_cell
        find_solo_options
    end

    def broadcast_cell(ci, cj)
        cell = @puzzle.cell(ci, cj)
        Turbo::StreamsChannel.broadcast_action_to(:cell_squares, action: :replace, target: "cell_#{cell.ci}_#{cell.cj}", partial: "sudoku/cell_square", locals: { value: cell.value, ci: cell.ci, cj: cell.cj, options: cell.options })
    end
end
