namespace :puzzles do
  desc "Generate JSON puzzles"
  task generate_json: :environment do
    puts "Generating JSON puzzles..."
    generator = PuzzleGenerator.new
    generator.generate_puzzles_to_json(4)
    puts "JSON puzzles generated and saved to app/assets/puzzle_matrices.json"
  end
end
