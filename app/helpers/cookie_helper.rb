require "Matrix"

module CookieHelper
  def save_game_state(puzzle_matrix, overwrite = false)
    return if (cookies[:values].present? || cookies[:options].present?) && !overwrite
    cookies[:values] = puzzle_matrix.values_array.to_s
    cookies[:options] = puzzle_matrix.options_array.to_s
  end

  def load_game_state
    options = cookies[:options]
    values = cookies[:values]
    return Game.new if !values
    options = JSON.parse(options)
    options = Matrix[*options]
    values = JSON.parse(values)
    values = Matrix[*values]
    matrix = PuzzleMatrix.new(values: values, options: options)
    Game.new(puzzle: matrix)
  end
end
