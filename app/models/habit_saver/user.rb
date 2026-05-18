class HabitSaver::User < ApplicationRecord
  self.table_name = "habit_saver_users"
  has_many :goals,
           class_name: "HabitSaver::Goal",
           foreign_key: :user_id,
           inverse_of: :user,
           dependent: :destroy
  has_many :habits,
           class_name: "HabitSaver::Habit",
           foreign_key: :user_id,
           inverse_of: :user,
           dependent: :destroy

  has_secure_password

  has_many :auth_sessions,
           class_name: "HabitSaver::AuthSession",
           foreign_key: :user_id,
           inverse_of: :user,
           dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.downcase.strip.presence
  end
end
