require "test_helper"

class HabitSaver::AuthSessionTest < Minitest::Test
  def setup
    HabitSaver::AuthSession.delete_all
    HabitSaver::OauthIdentity.delete_all
    HabitSaver::User.delete_all
  end

  def test_issues_a_digest_backed_session_token
    user = HabitSaver::User.create!(
      email: "issue@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    auth_session, raw_token = HabitSaver::AuthSession.issue_for!(
      user: user,
      user_agent: "Minitest",
      ip_address: "127.0.0.1"
    )

    assert raw_token.present?
    assert_equal HabitSaver::AuthSession.digest(raw_token), auth_session.session_token_digest
    assert auth_session.expires_at.future?
  end

  def test_active_scope_excludes_revoked_sessions
    user = HabitSaver::User.create!(
      email: "active@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    auth_session, = HabitSaver::AuthSession.issue_for!(
      user: user,
      user_agent: "Minitest",
      ip_address: "127.0.0.1"
    )

    assert_includes HabitSaver::AuthSession.active, auth_session

    auth_session.revoke!

    refute_includes HabitSaver::AuthSession.active, auth_session
  end
end
