class Portfolio::HomeController < ApplicationController
  def home

    @projects = [
      {
        title: "Sudoku Solver",
        image: "sudoku.png",
        description: "A web application that allows users to input a Sudoku puzzle and provides a solution using a human-like approach modeled in Ruby.",
        github_link: "https://github.com/marshallhelenm/sudoku-rails",
        live_link: "/sudoku"
      },
      {
        title: "Memetic",
        image: "question.png",
        description: "A web-based multiplayer game inspired by the classic “Guess Who?”, but with memes instead of cartoon faces! Built with Vite + React, react-use-websocket for real-time communication, and Material UI for sleek styling.",
        github_link: "https://github.com/marshallhelenm/memetic",
        live_link: "https://memetic-app-d0ed892a999c.herokuapp.com/"
      }
    ]
  end

  def about
  end

  def contact
  end
end