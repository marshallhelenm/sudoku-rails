require "Matrix"

module CookieHelper
  def save_game_state(puzzle, overwrite = false)
    return if (cookies[:values].present? || cookies[:options].present?) && !overwrite
    cookies[:values] = puzzle.values_array.to_s
    cookies[:options] = puzzle.options_array.to_s
  end

  def load_game_state
    options = cookies[:options]
    values = cookies[:values]
    return Puzzle.new if !values
    options = JSON.parse(options)
    options = Matrix[*options]
    values = JSON.parse(values)
    values = Matrix[*values]
    options.map { |opts| opts.to_set }
    options.each_with_index do |opts, ci, cj|
      options[ci, cj] = opts.to_set
    end
    Puzzle.new(values: values, options: options)
  end
end
