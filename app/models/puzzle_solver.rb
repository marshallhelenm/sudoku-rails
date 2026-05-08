class PuzzleSolver
    require_relative "sudoku"

    # Initializes the PuzzleSolver with a game instance.
    # @param game [Game] the game to solve
    # @param isolate [Boolean] whether to solve a duplicate of the puzzle
    # @param display [Boolean] whether to broadcast solving steps
    def initialize(game, isolate: false, display: false)
        unless game.is_a?(Game)
            raise ArgumentError, "game must be a Game"
        end
        unless [ true, false ].include?(isolate)
            raise ArgumentError, "isolate must be a boolean"
        end
        unless [ true, false ].include?(display)
            raise ArgumentError, "display must be a boolean"
        end

        if isolate
            @puzzle_matrix = game.puzzle_matrix.duplicate
            @game = Game.new(values: @puzzle_matrix)
        else
            @game = game
            @puzzle_matrix = game.puzzle_matrix
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
        @game.complete_and_valid?
    end

    private

    attr_reader :game, :puzzle_matrix, :display

    def prepare_puzzle
        @puzzle_matrix.reset_options
        @puzzle_matrix.cells.each do |cell|
            next if cell.value == 0
            @game.forbid_cell_relatives(cell)
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
        @game.complete? || passes_with_no_progress == 3
    end

    def try_solving_strategies
        low_hanging_fruit
        return true if @game.complete?
        find_families_in_vectors
        return true if @game.complete?
        find_families_in_blocks
        return true if @game.complete?
        find_sets
        return true if @game.complete?
        @game.update_values_found
    end

    # Fills in cells with only one possible value and finds solo options in groups until no more can be found.
    def low_hanging_fruit
        # keep looking for cells with only one option and groups where a value can only go in one cell until there are no more to find
        return if @game.complete?
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
            @puzzle_matrix.cells.each_with_index do |cell, i, j|
                still_searching = !(i == 8 && j == 8)
                next if cell.value != 0
                next unless cell.options.length == 1

                cell.value = cell.options[0]
                confirm_cell(cell.options[0], i, j)
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
        @game.puzzle_groups.each do |group|
            remaining = group.remaining_values
            remaining.each do |num|
                possible_cell = nil
                group.cells.each do |cell|
                    next if cell.value != 0
                    next unless cell.can_be?(num)
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
        unless group.respond_to?(:cells)
            raise ArgumentError, "group must respond to :cells"
        end
        families = {}
        Sudoku::ZERO_RANGE.each do |num|
            families[num] = []
            family = []
            group.cells.each do |cell|
                family << cell if cell.can_be?(num)
                break if family.length > size
            end
            families[num] << family if family.length <= 3 && family.length > 1
        end
        families
    end

    # Applies family-finding logic to all vectors (rows and columns).
    def find_families_in_vectors
        @puzzle_matrix.vectors.each do |vector|
            break if @game.complete?
            # check each group for a value that can only appear in one of two or three cells
            families = find_families_in_group(vector)
            # if all cells in the family fall within the same block, then no other cells in the block can have that value
            families.each_key do |value|
                families[value].each do |family|
                    if family.collect(&:block_coordinates).uniq.length == 1
                        @puzzle_matrix.block_from_cell(family[0]).cells.each do |cell|
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
        @puzzle_matrix.blocks.each do |block|
            break if @game.complete?
            # check each block for a value that can only appear in one of two or three cells
            families = find_families_in_group(block)
            # if all cells in the family fall within the same row or column, then no other cells in that row or column can have that value
            families.each_key do |value|
                families[value].each do |family|
                    if family.collect(&:ci).uniq.length == 1
                        @puzzle_matrix.row_from_cell(family[0]).cells.each do |cell|
                            next if family.include?(cell)
                            cell.forbid(value)
                        end
                    elsif family.collect(&:cj).uniq.length == 1
                        @puzzle_matrix.column_from_cell(family[0]).cells.each do |cell|
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
        Range(2, 6).each do |size|
            break if @game.complete?
            @game.puzzle_groups.each do |group|
                # look for a set of numbers of size n where n cells can only contain any of those numbers
                # for example, only 2 cells can be a [1,2]
                # or only 3 cells can be a [4,5,6]
                # this could look like [[1,2,3], [1,2,3], [1,2,3]] or [[1,3], [1,2], [1,2,3]]
                # only goes up to size 5 because any higher and you're better off using other elimination strategies
                return if @game.complete?
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
        unless value.is_a?(Integer) && value > 0 && value <= 9
            raise ArgumentError, "value must be an integer between 1 and 9"
        end
        unless ci.is_a?(Integer) && ci >= 0 && ci <= 8
            raise ArgumentError, "ci must be an integer between 0 and 8"
        end
        unless cj.is_a?(Integer) && cj >= 0 && cj <= 8
            raise ArgumentError, "cj must be an integer between 0 and 8"
        end
        # assign the value to the cell and forbid that value in all siblings
        # also broadcast the change if we're displaying the solving process
        # then check for any new single option cells or solo options that may have been revealed by this change
        @game.confirm_cell(value, ci, cj)
        @game.broadcast_cell(ci, cj) if @display
        find_single_option_cell
        find_solo_options
    end
end
