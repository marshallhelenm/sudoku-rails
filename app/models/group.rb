
# Group represents a collection of Cell objects (row, column, or block) in a Sudoku puzzle.
# Provides validation and utility methods for group logic.
class Group
    # Initialize a Group with an array of Cell objects.
    # Raises ArgumentError if cells is not an array of Cell objects.
    def initialize(cells)
        unless cells.is_a?(Array) && cells.length == 9 && cells.all? { |c| c.respond_to?(:value) && c.respond_to?(:empty?) && c.respond_to?(:options_include?) }
            raise ArgumentError, "cells must be an array of 9 Cell-like objects"
        end
        @cells = cells
    end

    # Array of Cell objects in this group
    attr_reader :cells

    # Return all empty cells in the group
    def empty_cells
        @cells.select(&:empty?)
    end

    # Return all possible Sudoku values (1-9)
    def possible_values
        Array(1..9)
    end

    # Return values not yet used in the group
    def remaining_values
        possible_values - values
    end

    # Return the values of all cells in the group
    def values
        @cells.collect(&:value)
    end

    # Return true if all values in the group are unique (no repeats)
    def values_valid?
        confirmed_values = values.reject { |v| v == 0 }
        confirmed_values.uniq.length == confirmed_values.length
    end

    # Return true if every remaining value can be placed in at least one cell,
    # and no empty cell has zero options.
    def options_valid?
        valid = true
        values_needed = remaining_values.dup
        @cells.each do |cell|
            next if !cell.empty?

            if cell.options.empty?
                valid = false
                break
            end
            values_needed.each do |value|
                if cell.options_include?(value)
                    values_needed.delete(value)
                end
            end
        end
        valid && values_needed.empty?
    end

    def valid?
        # A group is valid if all confirmed values are unique and all remaining values can still be placed in the group based on the options of empty cells. This version of the valid? method loops through the cells once, checking both conditions in a single pass for efficiency.
        valid = true
        confirmed_values = Set.new
        remaining_options = Set.new
        cells.each do |cell|
            if cell.empty?
                if cell.options.empty?
                    # If an empty cell has no options, the group is invalid
                    valid = false
                    break
                else
                    # Collect all options from empty cells to ensure remaining values can still be placed
                    remaining_options.merge(cell.options)
                end
            elsif confirmed_values.include?(cell.value)
                # If a confirmed value is repeated in the group, it's invalid
                valid = false
                break
            else
                # Collect confirmed values to check for duplicates
                confirmed_values << cell.value
            end
        end
        # The last check is to ensure that all remaining values can still be placed in the group based on the options of empty cells
        valid && remaining_values.to_set.subset?(remaining_options)
    end

    # Forbid a value in all cells of the group
    def forbid_value(value)
        @cells.each { |cell| cell.forbid(value) }
    end

    def complete?
        @cells.all? { |cell| cell.value != 0 }
    end

    def incomplete?
        !complete?
    end
end
