module Sudoku
  require "json"

  root_path = defined?(Rails) && Rails.respond_to?(:root) ? Rails.root : File.expand_path("../..", __dir__)
  JSON_PUZZLES = File.read(File.join(root_path, "app/assets/puzzle_matrices.json"))
  VALUE_RANGE = Array(0..9).freeze
  OPTIONS_RANGE = Array(1..9).freeze
  COORD_RANGE = Array(0..8).freeze

  def self.load_puzzles
    data = JSON.parse(JSON_PUZZLES)
    data.each_key do |difficulty|
      data[difficulty] = data[difficulty].map { |puzzle_data| Sudoku::Puzzle.new(values: Matrix[*puzzle_data]) }
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

  def self.broadcast_cell(cell, display: false, display_speed: nil)
    return unless display || display_speed.present?

    show_options = [ "slow", "medium" ].include?(display_speed)
    Turbo::StreamsChannel.broadcast_action_to(
      :cell_squares,
      action: :replace,
      target: "cell_#{cell.ci}_#{cell.cj}",
      partial: "sudoku/solver/cell_square",
      locals: { value: cell.value, ci: cell.ci, cj: cell.cj, options: cell.options, show_options: show_options }
    )

    case display_speed
    when "slow"
      sleep(0.1)
    when "medium"
      sleep(0.025)
    end
  end
end
