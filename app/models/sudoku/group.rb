# Group represents a collection of Cell objects (row, column, or block) in a Sudoku puzzle.
# Provides validation and utility methods for group logic.

require_relative "../sudoku"

class Sudoku::Group
    require_relative "puzzle"

    # Initialize a Group with an array of Cell objects.
    # Raises ArgumentError if cells is not an array of Cell objects.
    def initialize(cells)
        unless cells.is_a?(Array) && cells.length == 9 && cells.all? { |c| c.respond_to?(:value) && c.respond_to?(:empty?) && c.respond_to?(:options_include?) } && validate_cell_order(cells)
            raise ArgumentError, "cells must be an array of 9 Cell-like objects, ordered correctly for the group type"
        end
        @cells = cells
        @cache = blank_cache
    end

    attr_reader :group_number, :group_type

    # Array of Cell objects in this group
    # attr_reader :cells (removed to allow custom method with debug logging)
    def cells
        @cells
    end

    def validate_cell_order(cells)
        true # default implementation does no validation, overridden in Row and Column subclasses
    end

    def group_cache
        @cache ||= blank_cache
    end

    def complete?
        group_cache.cache_or_compute(:complete) { cells.all? { |cell| cell.value != 0 } }
    end

    def incomplete?
        !complete?
    end

    # Return all empty cells in the group
    def blank_cells
        group_cache.cache_or_compute(:blank_cells) { cells.select { |cell| cell.empty? } }
    end

    # Return values not yet used in the group
    def remaining_values
        group_cache.cache_or_compute(:remaining_values) { Set.new(1..9) - values }
    end

    # Return the values of all cells in the group
    def values
        group_cache.cache_or_compute(:values) { cells.collect { |cell| cell.value } }
    end

    def values_array
        group_cache.cache_or_compute(:values_array) { cells.collect { |cell| cell.value } }
    end

    def options_array
        group_cache.cache_or_compute(:options_array) { cells.collect { |c| c.options.to_a } }
    end

    # Return true if all values in the group are unique (no repeats)
    def values_valid?
        group_cache.cache_or_compute(:values_valid) do
            confirmed_values = values.reject { |v| v == 0 }
            confirmed_values.uniq.length == confirmed_values.length
        end
    end

    # Return true if every remaining value can be placed in at least one cell,
    # and no empty cell has zero options.
    def options_valid?
        group_cache.cache_or_compute(:options_valid) do
            valid = true
            values_needed = remaining_values.dup
            cells.each do |cell|
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
    end

    def valid?
        group_cache.cache_or_compute(:valid) { assess_validity }
    end

    def assess_validity
        # A group is valid if all confirmed values are unique and all remaining values can still be placed in the group based on the options of empty cells. This version of the valid? method loops through the cells once, checking both conditions in a single pass for efficiency.
        valid = true
        confirmed_values = Set.new
        remaining_options = Set.new
        current_blank_cells = []

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
                current_blank_cells << cell
            elsif confirmed_values.include?(cell.value)
                # If a confirmed value is repeated in the group, it's invalid
                valid = false
                break
            else
                # Collect confirmed values to check for duplicates
                confirmed_values << cell.value
            end
        end
        # cache all this great info we just found
        group_cache.replace_cache(:values, confirmed_values)
        group_cache.recompute_cache(:remaining_values) { remaining_values }
        group_cache.replace_cache(:blank_cells, current_blank_cells)
        group_cache.recompute_cache(:complete) { remaining_values.empty? }
        group_cache.replace_cache(:values_valid, valid)

        # The last check is to ensure that all remaining values can still be placed in the group based on the options of empty cells
        opts_valid = valid && remaining_values.to_set.subset?(remaining_options)
        group_cache.replace_cache(:options_valid, opts_valid)
        opts_valid
    end

    # Forbid a value in all cells of the group
    def forbid_value(value)
        cells.each { |cell| cell.forbid(value) }
    end

    def bust_cache
        group_cache&.bust_entire_cache
    end

    private

    def blank_cache
        Sudoku::SudokuCache.new({
            valid: { current: false, value: nil },
            complete: { current: false, value: nil },
            options_valid: { current: false, value: nil },
            values_valid: { current: false, value: nil },
            values: { current: false, value: nil },
            options_array: { current: false, value: nil },
            remaining_values: { current: false, value: nil },
            blank_cells: { current: false, value: nil }
        })
    end
end
