class CreateHabitSaverAuthSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_saver_auth_sessions do |t|
      t.references :user, null: false, foreign_key: { to_table: :habit_saver_users }
      t.string :session_token_digest, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :habit_saver_auth_sessions, :session_token_digest, unique: true
    add_index :habit_saver_auth_sessions, :expires_at
  end
end
