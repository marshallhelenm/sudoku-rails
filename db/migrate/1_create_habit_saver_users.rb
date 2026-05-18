class CreateHabitSaverUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_saver_users do |t|
      t.string :email
      t.string :display_name
      t.string :password_digest
      
      t.timestamps
    end

    add_index :habit_saver_users, :email, unique: true
  end
end
