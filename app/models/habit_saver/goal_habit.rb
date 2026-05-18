class HabitSaver::GoalHabit < ApplicationRecord
  self.table_name = "goal_habits"

  belongs_to :habit,
             class_name: "HabitSaver::Habit",
             inverse_of: :goal_habits
  belongs_to :goal,
             class_name: "HabitSaver::Goal",
             inverse_of: :goal_habits
end
