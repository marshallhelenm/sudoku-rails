class SudokuController < ApplicationController
  include ApplicationHelper
  def sudoku_solver
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
    if @puzzle.confirmed_count < 17
      render turbo_stream: turbo_stream.replace("message_card", partial: "sudoku/message_card", locals: { message_type: "warning", message_text: "This puzzle has fewer than 17 clues, which is below the known threshold for a unique solution!" })
      return
    end
    solver = PuzzleSolver.new(@puzzle, display: true, slow_display: params[:speed] == "slow")
    success = solver.solve
    render turbo_stream: [
      turbo_stream.replace("message_card", partial: "sudoku/message_card", locals: { message_type: success ? "" : "failure", message_text: success ? "" : "Oops, I couldn't solve that puzzle." }),
      turbo_stream.replace("game_board", partial: "sudoku/game_board", locals: { puzzle: @puzzle, solved: true })
    ]
    save_game_state(@puzzle, true)
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
