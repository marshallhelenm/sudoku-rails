class SudokuController < ApplicationController
  include ApplicationHelper
  def puzzler
    @puzzle = load_game_state
    @puzzle = @puzzle.present? ? @puzzle : set_new_puzzle
  end

  def new_puzzle
    puzzle = set_new_puzzle
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("game_board", partial: "sudoku/game_board", locals: { puzzle: puzzle })
      end
    end
  end

  def solve_puzzle
    @puzzle = load_game_state
    solver = PuzzleSolver.new(@puzzle, display: true)
    solver.solve
  end

  def generate_puzzles
    generator = PuzzleGenerator.new
    generator.generate_puzzles(5, 1)
    @failed_puzzle = generator.failed_puzzles.sample

    if @failed_puzzle
      Turbo::StreamsChannel.broadcast_action_to(:game_board, action: :replace, target: "game_board", partial: "sudoku/game_board", locals: { puzzle: @failed_puzzle })
    end
  end

  private

  def set_new_puzzle
    puzzles = Sudoku.load_puzzles
    puzzle = puzzles.sample
    save_game_state(puzzle)
    puzzle
  end
end
