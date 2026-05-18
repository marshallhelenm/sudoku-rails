class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.string :name
      t.float :target_amount
      t.float :total_saved
      t.float :daily_earnings_cap
      t.references :user, null: false, foreign_key: { to_table: :habit_saver_users }

      t.timestamps
    end
  end
end
