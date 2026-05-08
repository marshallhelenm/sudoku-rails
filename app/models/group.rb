
# Group represents a collection of Cell objects (row, column, or block) in a Sudoku puzzle.
# Provides validation and utility methods for group logic.
class Group
    # Initialize a Group with an array of Cell objects.
    # Raises ArgumentError if cells is not an array of Cell objects.
    def initialize(cells)
        unless cells.is_a?(Array) && cells.length == 9 && cells.all? { |c| c.respond_to?(:value) && c.respond_to?(:empty?) && c.respond_to?(:can_be?) }
            raise ArgumentError, "cells must be an array of 9 Cell-like objects"
        end
        @cells = cells
        @values = cells.collect(&:value)
    end

    # Array of Cell objects in this group
    attr_accessor :cells
    # Array of values for the cells in this group
    attr_accessor :values

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
        possible_values - @values
    end

    # Return true if all values in the group are unique (no repeats)
    def values_valid?
        confirmed_values = @values.reject { |v| v == 0 }
        confirmed_values.uniq.length == confirmed_values.length
    end

    # Return true if every remaining value can be placed in at least one cell,
    # and no empty cell has zero options.
    def options_valid?
        valid = true
        remaining_values.each do |value|
            valid = @cells.any? do |cell|
                cell.can_be?(value)
            end
            break unless valid
        end
        return false unless valid
        valid = cells.any? { |cell| cell.empty? && cell.options.length == 0 } ? false : true
        # Additional checks could be added for stricter validation
        valid
    end

    # Return true if both values and options are valid for the group
    def valid?
        values_valid? && options_valid?
    end

    # Forbid a value in all cells of the group
    def forbid_value(value)
        @cells.each { |cell| cell.forbid(value) }
    end
end
