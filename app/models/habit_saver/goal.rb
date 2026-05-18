class HabitSaver::Goal < ApplicationRecord
  self.table_name = "goals"

  belongs_to :user,
             class_name: "HabitSaver::User",
             inverse_of: :goals
  has_many :goal_habits,
           class_name: "HabitSaver::GoalHabit",
           foreign_key: :goal_id,
           inverse_of: :goal,
           dependent: :destroy
  has_many :habits,
           through: :goal_habits,
           class_name: "HabitSaver::Habit"

  validates :name, length: { maximum: 255 }, presence: true
  validates :target_amount, numericality: { greater_than: 0 }
  validates :daily_earnings_cap, numericality: { greater_than: 0 }
  validates :total_saved, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
