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
    root to: "app#dashboard"
    get "login" => "app#login_page"
    post "signup" => "auth#signup", as: :signup
    post "session" => "auth#login", as: :session
    delete "logout" => "auth#logout", as: :logout
    resources :goals, only: [:create]
    resources :habits, only: [:create]
  end
end
