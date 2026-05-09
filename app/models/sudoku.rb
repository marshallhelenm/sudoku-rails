class Sudoku
    root_path = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : File.expand_path("../..", __dir__)
    JSON_PUZZLES = File.read(File.join(root_path, "app/assets/puzzle_matrices.json"))
    VALUE_RANGE = Array(0..9).freeze
    OPTIONS_RANGE = Array(1..9).freeze
    COORD_RANGE = Array(0..8).freeze

    def self.load_puzzles
        puzzles = []
        data = JSON.parse(JSON_PUZZLES)
        data.each do |puzzle_data|
            puzzle = Puzzle.new(values: Matrix[*puzzle_data])
            puzzles << puzzle
        end
        puzzles
    end
end
