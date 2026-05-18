# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

test_user_email = "test_user@example.com"
test_user_password = "password123"

user = HabitSaver::User.find_or_initialize_by(email: test_user_email)
user.display_name = "Test User"
user.password = test_user_password
user.password_confirmation = test_user_password
user.save!

puts "Seeded Habit Saver test user: #{test_user_email} / #{test_user_password}"
