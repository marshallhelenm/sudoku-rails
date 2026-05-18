Rails.application.routes.draw do
  mount ActionCable.server => "/cable"
  root to: "portfolio/home#home"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :portfolio do
    root to: "home#home"
  end

  namespace :sudoku do
    root to: "solver#sudoku_solver"
    patch "solve_puzzle" => "solver#solve_puzzle"
    patch "new_puzzle" => "solver#new_puzzle"
    patch "generate_puzzles" => "solver#generate_puzzles"
  end

  namespace :habit_saver do
    get "habit_saver" => "app#home"
  end
end
