namespace :puzzles do
  desc "Generate JSON puzzles"
  task generate_json: :environment do
    puts "How many puzzles do you want to generate?"
    num_puzzles = STDIN.gets.chomp
    num_puzzles = num_puzzles.to_i
    puts "What difficulty level? (easy, medium, hard)"
    difficulty = STDIN.gets.chomp.downcase.to_sym
    puts "Should we display the generation process in the console? (y/n)"
    display_process = STDIN.gets.chomp.downcase == "y"
    puts "Generating JSON puzzles..."
    generator = Sudoku::PuzzleGenerator.new(print_progress: display_process)
    generator.generate_puzzles_to_json(num_puzzles, difficulty: difficulty)
    puts "JSON puzzles generated and saved to app/assets/puzzle_matrices.json"
  end
end
