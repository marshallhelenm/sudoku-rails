class CreateHabits < ActiveRecord::Migration[8.1]
  def change
    create_table :habits do |t|
      t.string :name
      t.integer :current_streak, default: 0, null: false
      t.integer :streak_record, default: 0, null: false
      t.string :time_unit, default: "day", null: false
      t.integer :target_per_unit, default: 1, null: false
      t.datetime :last_day
      t.integer :tally, default: 0, null: false
      t.references :user, null: false, foreign_key: { to_table: :habit_saver_users }

      t.timestamps
    end
  end
end
