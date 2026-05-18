class HabitSaver::Habit < ApplicationRecord
  self.table_name = "habits"

  belongs_to :user,
             class_name: "HabitSaver::User",
             inverse_of: :habits
  has_many :goal_habits,
           class_name: "HabitSaver::GoalHabit",
           foreign_key: :habit_id,
           inverse_of: :habit,
           dependent: :destroy
  has_many :goals,
           through: :goal_habits,
           class_name: "HabitSaver::Goal"

  validates :name, presence: true
  validates :target_per_unit, numericality: { only_integer: true, greater_than: 0 }
  validates :time_unit, inclusion: { in: %w[day week month] }
end
