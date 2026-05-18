class HabitSaver::AuthController < ApplicationController
  include HabitSaverControllerSupport
  layout "habit_saver"
  def signup
    user = HabitSaver::User.new(signup_params)
    if user.save
      issue_session_for(user)
      redirect_to habit_saver_root_path, notice: "Account created. Welcome to Habit Saver."
      return
    end

    @signup_user = user
    flash.now[:alert] = user.errors.full_messages.to_sentence
    render "habit_saver/login_page", status: :unprocessable_entity
  end

  def login
    email = login_params[:email].to_s.downcase
    user = HabitSaver::User.find_by(email: email)

    if user&.authenticate(login_params[:password])
      issue_session_for(user)
      redirect_to habit_saver_root_path, notice: "Logged in successfully."
      return
    end

    @signup_user = HabitSaver::User.new(email: email)
    flash.now[:alert] = "Invalid email or password."
    render "habit_saver/login_page", status: :unprocessable_entity
  end

  def logout
    current_habit_saver_auth_session&.revoke!
    session.delete(:habit_saver_session_token)
    @current_habit_saver_auth_session = nil
    @current_habit_saver_user = nil
    redirect_to habit_saver_login_path, notice: "You have been logged out."
  end

  private

  def login_params
    params.require(:session).permit(:email, :password)
  end

  def signup_params
    params.require(:habit_saver_user).permit(:email, :display_name, :password, :password_confirmation)
  end

end