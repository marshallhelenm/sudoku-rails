
# Sudoku-a

A web-based Sudoku puzzle application built with Ruby on Rails. This project began with the desire to code a program that would solve Sudoku puzzles, not necessarily in the most efficient way, but in a way that models a human-like approach to the puzzle.

## Features

- Play Sudoku puzzles of varying difficulty
- Solve puzzles automatically
- Interactive game board with Turbo/Stimulus for SPA-like experience
- Puzzle logic and validation in Ruby
- JSON-based puzzle storage

## Getting Started

### Prerequisites

- Ruby (compatible with Rails 8.1.3)
- Bundler
- Node.js (for asset pipeline, if needed)
- PostgreSQL

### Installation

1. Clone the repository:
	```sh
	git clone <repo-url>
	cd sudoku-a
	```

2. Install dependencies:
	```sh
	bundle install
	```

3. Set up the database:
	```sh
	rails db:setup
	```

4. (Optional) Generate new puzzles:
	```sh
	rake puzzles:generate_json
	```

5. Start the server:
	```sh
	rails s
	```

6. Visit `http://localhost:3000/sudoku/solver` in your browser.

## Project Structure

- `app/models/` — Core puzzle logic (`sudoku.rb`, `puzzle.rb`, `puzzle_solver.rb`, etc.)
- `app/controllers/` — Main controller: `sudoku_controller.rb`
- `app/views/sudoku/` — Game board and UI partials
- `app/assets/puzzle_matrices.json` — JSON file with puzzle data
- `Gemfile` — Rails, Turbo, Stimulus, and other dependencies

## Usage

- Play Sudoku puzzles in your browser.
- Generate new puzzles or solve existing ones.
- The game board is interactive and updates via Turbo Streams.

## Testing

Run the test suite with:
```sh
rails test
```

## Deployment

- Dockerfile included for containerized deployment.
- See `config/deploy.yml` for deployment configuration.

<img width="799" height="690" alt="Screenshot 2026-05-11 at 9 13 05 PM" src="https://github.com/user-attachments/assets/90ed4292-603b-4f19-9beb-eaff885d83d9" />

