# frozen_string_literal: true

namespace :puzzles do
  desc "Generate JSON puzzles"
  task generate_json: :environment do
    # TODO: Add puzzle generation logic here
    puts "Generating JSON puzzles..."
    generator = PuzzleGenerator.new
    generator.generate_puzzles_to_json(100)
    puts "JSON puzzles generated and saved to app/assets/puzzle_matrices.json"
  end
end
