class HabitSaver::AppController < ApplicationController
  include HabitSaverControllerSupport
  layout "habit_saver"

  before_action :require_habit_saver_login, except: [ :login_page ]

  def dashboard
    @habit_saver_user = current_habit_saver_user
    load_dashboard_data
    initialize_dashboard_forms
    render "habit_saver/dashboard"
  end

  def login_page
    if current_habit_saver_user.present?
      redirect_to habit_saver_root_path
      return
    end

    @signup_user = HabitSaver::User.new
    render "habit_saver/login_page"
  end

  

  private
end