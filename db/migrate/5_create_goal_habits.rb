class CreateGoalHabits < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_habits do |t|
      t.references :habit, null: false, foreign_key: true
      t.references :goal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
