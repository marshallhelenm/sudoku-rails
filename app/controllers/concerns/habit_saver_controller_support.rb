module HabitSaverControllerSupport
  extend ActiveSupport::Concern

  private

  def require_habit_saver_login
    return if current_habit_saver_user.present?

    redirect_to habit_saver_login_path, alert: "Please log in to continue."
  end

  def require_habit_saver_user
    require_habit_saver_login
  end

  def issue_session_for(user)
    _auth_session, raw_session_token = HabitSaver::AuthSession.issue_for!(
      user: user,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    reset_session
    session[:habit_saver_session_token] = raw_session_token
  end

  def current_habit_saver_user
    return @current_habit_saver_user if defined?(@current_habit_saver_user)

    @current_habit_saver_user = current_habit_saver_auth_session&.user
  end

  def current_habit_saver_auth_session
    return @current_habit_saver_auth_session if defined?(@current_habit_saver_auth_session)

    raw_session_token = session[:habit_saver_session_token]
    if raw_session_token.blank?
      @current_habit_saver_auth_session = nil
      return
    end

    auth_session = HabitSaver::AuthSession.active.find_by(
      session_token_digest: HabitSaver::AuthSession.digest(raw_session_token)
    )

    if auth_session.nil?
      session.delete(:habit_saver_session_token)
      @current_habit_saver_auth_session = nil
      return
    end

    auth_session.touch_last_seen!
    @current_habit_saver_auth_session = auth_session
  end

  def load_dashboard_data
    @goals = @habit_saver_user.goals.order(created_at: :desc)
    @habits = @habit_saver_user.habits.order(created_at: :desc)
  end

  def initialize_dashboard_forms(goal: nil, habit: nil)
    @goal = goal || @habit_saver_user.goals.build(total_saved: 0)
    @habit = habit || @habit_saver_user.habits.build
  end
end