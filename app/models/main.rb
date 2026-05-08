#!/usr/bin/env ruby
require "matrix"
require "byebug"
require "./puzzle_solver"
require "./puzzle_generator"
require "./puzzle"
require "./cell"

def main
    easy = Matrix[
        [ 1, 0, 0, 2, 4, 9, 0, 0, 6 ],
        [ 0, 4, 0, 0, 0, 0, 0, 0, 0 ],
        [ 9, 7, 0, 0, 0, 1, 0, 0, 2 ],
        [ 0, 8, 3, 6, 0, 0, 0, 7, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 1, 0, 0, 0, 3, 5, 6, 0 ],
        [ 2, 0, 0, 5, 0, 0, 0, 4, 1 ],
        [ 0, 0, 0, 0, 0, 0, 0, 9, 0 ],
        [ 3, 0, 0, 7, 6, 4, 0, 0, 5 ]
        ]

    basic = Matrix[
        [ 0, 4, 0, 3, 8, 0, 6, 0, 0 ],
        [ 3, 0, 0, 0, 0, 0, 7, 0, 2 ],
        [ 0, 9, 0, 0, 6, 7, 0, 1, 0 ],
        [ 0, 3, 0, 9, 0, 0, 0, 0, 0 ],
        [ 0, 0, 4, 0, 0, 0, 1, 0, 0 ],
        [ 0, 0, 0, 0, 0, 8, 0, 9, 0 ],
        [ 0, 8, 0, 5, 4, 0, 0, 7, 0 ],
        [ 1, 0, 9, 0, 0, 0, 0, 0, 5 ],
        [ 0, 0, 5, 0, 9, 3, 0, 2, 0 ]
        ]

    intermediate = Matrix[
        [ 0, 0, 0, 0, 2, 0, 7, 0, 0 ],
        [ 5, 0, 0, 0, 4, 0, 6, 0, 0 ],
        [ 0, 2, 0, 3, 0, 0, 0, 0, 9 ],
        [ 0, 8, 0, 2, 0, 0, 0, 5, 0 ],
        [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ],
        [ 0, 4, 0, 0, 0, 5, 0, 3, 0 ],
        [ 8, 0, 0, 0, 0, 6, 0, 9, 0 ],
        [ 0, 0, 1, 0, 7, 0, 0, 0, 6 ],
        [ 0, 0, 9, 0, 1, 0, 0, 0, 0 ]
        ]


    # puzzle = Game.new(easy)
    # puzzle = Game.new(basic)
    # puzzle = Game.new(intermediate)
    # solver = PuzzleSolver.new(puzzle)
    # solver.solve(display:true)
    # puzzle.print_puzzle
    generator = PuzzleGenerator.new
    # generator.generate_completed_puzzle
    puzzles = generator.generate_puzzles(5)
    10.times do
        puts ""
    end
    puzzles.each do |puzzle|
        puts "*****************"
        puzzle.print_puzzle
        puzzle.print_puzzle_information
        solver = PuzzleSolver.new(puzzle)
        solver.solve(display: true, print_puzzle: true)
        puzzle.print_puzzle_information
        puts "*****************"
    end
end


# save file and make it executable by running:
# chmod +x main.rb

main if __FILE__ == $PROGRAM_NAME
