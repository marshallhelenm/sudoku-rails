Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root to: "home#home"


  # sudoku routes
  get "sudoku_solver" => "sudoku#sudoku_solver"
  patch "solve_puzzle" => "sudoku#solve_puzzle"
  patch "new_puzzle" => "sudoku#new_puzzle"
  patch "generate_puzzles" => "sudoku#generate_puzzles"

end
