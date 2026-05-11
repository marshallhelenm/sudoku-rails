class SudokuController < ApplicationController
  include ApplicationHelper
  def puzzler
    @puzzle = load_game_state
    @difficulty = params[:difficulty] || "medium"
    @puzzle = @puzzle.present? ? @puzzle : set_new_puzzle(@difficulty || "medium")
  end

  def new_puzzle
    difficulty = params[:difficulty] || "medium"
    puzzle = set_new_puzzle(difficulty)
    save_game_state(puzzle, true)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("game_board", partial: "sudoku/game_board", locals: { puzzle: puzzle })
      end
    end
  end

  def solve_puzzle
    @puzzle = load_game_state
    solver = PuzzleSolver.new(@puzzle, display: true)
    success = solver.solve
    render turbo_stream: turbo_stream.replace("result", partial: "sudoku/result", locals: { success: success.to_s })
  end

  def generate_puzzles
    generator = PuzzleGenerator.new
    generator.generate_puzzles(5, "medium")
    @failed_puzzle = generator.failed_puzzles.sample
  end

  private

  def set_new_puzzle(difficulty = "medium")
    puzzles = Sudoku.load_puzzles
    puzzle = puzzles[difficulty].sample
    save_game_state(puzzle)
    puzzle
  end
end
