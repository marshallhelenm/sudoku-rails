class Sudoku
    root_path = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : File.expand_path("../..", __dir__)
    PUZZLES = File.read(File.join(root_path, "app/assets/puzzle_matrices.json"))
    VALUE_RANGE = Array(0..9).freeze
    OPTIONS_RANGE = Array(1..9).freeze
    ZERO_RANGE = Array(0..8).freeze

    def randomize(values)
        values.sort { rand() - 0.5 }
    end
end
