class Sudoku
    root_path = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : File.expand_path("../..", __dir__)
    JSON_PUZZLES = File.read(File.join(root_path, "app/assets/puzzle_matrices.json"))
    VALUE_RANGE = Array(0..9).freeze
    OPTIONS_RANGE = Array(1..9).freeze
    COORD_RANGE = Array(0..8).freeze

    def self.load_puzzles
        data = JSON.parse(JSON_PUZZLES)
        data.each_key do |difficulty|
            data[difficulty] = data[difficulty].map { |puzzle_data| Puzzle.new(values: Matrix[*puzzle_data]) }
        end
        data
    end

    def self.all_puzzles
        @all_puzzles ||= load_puzzles.values.flatten
    end

    def self.puzzles_by_difficulty(difficulty)
        load_puzzles[difficulty.to_s]
    end

    def self.random_puzzle(difficulty = "medium")
        puzzles = puzzles_by_difficulty(difficulty)
        puzzles.sample
    end
end
