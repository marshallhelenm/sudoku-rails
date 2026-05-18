require "digest"

class HabitSaver::AuthSession < ApplicationRecord
  self.table_name = "habit_saver_auth_sessions"

  SESSION_TTL = 30.days

  belongs_to :user,
             class_name: "HabitSaver::User",
             inverse_of: :auth_sessions

  validates :session_token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user:, user_agent:, ip_address:, ttl: SESSION_TTL)
    raw_token = SecureRandom.hex(48)
    auth_session = create!(
      user: user,
      session_token_digest: digest(raw_token),
      user_agent: user_agent,
      ip_address: ip_address,
      last_seen_at: Time.current,
      expires_at: Time.current + ttl
    )

    [ auth_session, raw_token ]
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_seen!
    update_column(:last_seen_at, Time.current)
  end
end
