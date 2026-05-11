class FamilyHandler
    require_relative "sudoku"

    # Initializes the FamilyHandler with a puzzle instance.
    # @param puzzle [Puzzle] the puzzle to solve
    def initialize(solver, puzzle)
        unless puzzle.is_a?(Puzzle)
            raise ArgumentError, "puzzle must be a Puzzle"
        end
        unless solver.is_a?(PuzzleSolver)
            raise ArgumentError, "solver must be a PuzzleSolver"
        end
        @solver = solver
        @puzzle = puzzle
    end

    # -- Family strategies --

    # A family is a group of 2-3 cells within one group (row, column, or block) that are the only possible locations for a given value.
    # For example, if only 2 cells in a row can be a 5, those cells are a family for the value 5.
    # If the group we started with is a column or row, and if those 2 cells are also the only cells in their block that can be a 5, then no other cell in that block can be a 5.
    # If the group we started with is a block, and if those 2 cells are also the only cells in their row that can be a 5, then no other cell in that row can be a 5.
    # Same logic applies for columns.

    # Finds families of cells in a group that are the only possible locations for certain values
    # eg only 3 cells can be a 1
    # @param group [Group] the group to search
    # @return [Hash] a hash where keys are values and values are arrays of coordinates for cells that form a family for that value
    def find_families_in_group(group)
        raise ArgumentError, "group must be a Group" unless group.is_a?(Group)
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
                @solver.confirm_cell(cell, num)
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
      if group.is_a?(Row) || group.is_a?(Column)
        forbid_other_cells_in_vector_for_family(value: value, values: values, family: family)
      elsif group.is_a?(Block)
        forbid_other_cells_in_block_for_family(value: value, values: values, family: family)
      else
        raise ArgumentError, "group must be a Row, Column, or Block"
      end
    end

    def forbid_other_cells_in_block_for_family(value: nil, values: [], family:)
        # if all cells in the family fall within the same block, then no other cells in the block can have that value
        return false if family.map { |coordinates| Cell.block_coordinates_for(coordinates.first, coordinates.last) }.uniq.length > 1
        #
        block_coordinates = Cell.block_coordinates_for(family.first.first, family.first.last)
        block = @puzzle.block(block_coordinates.first, block_coordinates.last)

        block.cells.each do |cell|
            next if family.include?(cell.coordinates) || cell.value != 0
            if value.present?
                cell.forbid(value)
            elsif values.present?
                cell.forbid_multiple(values)
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
                    cell.forbid(value)
                elsif values.present?
                    cell.forbid_multiple(values)
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
                    cell.forbid(value)
                elsif values.present?
                    cell.forbid_multiple(values)
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
            @solver.low_hanging_fruit
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
                @solver.low_hanging_fruit
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
end
