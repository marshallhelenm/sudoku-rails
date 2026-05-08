class SudokuController < ApplicationController
  include CookieHelper
  def puzzler
    @game = load_game_state
    @puzzle = @game.present? ? @game.puzzle_matrix : set_new_puzzle
  end

  def new_puzzle
    puzzle = set_new_puzzle
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("game_board", partial: "sudoku/game_board", locals: {puzzle: puzzle})
      end
    end
  end

  def solve_puzzle
    @game = load_game_state
    @puzzle = @game.puzzle_matrix
    solver = PuzzleSolver.new(@game, display: true)
    solver.solve
  end

  private

  def set_new_puzzle
    puzzles = PuzzleGenerator.load_puzzles
    game = puzzles.sample
    puzzle = game.puzzle_matrix
    save_game_state(puzzle)
    return puzzle
  end
end
