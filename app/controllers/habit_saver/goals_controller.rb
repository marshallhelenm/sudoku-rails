class HabitSaver::GoalsController < ApplicationController
  include HabitSaverControllerSupport

  before_action :require_habit_saver_user

  def create
    @habit_saver_user = current_habit_saver_user
    @goal = @habit_saver_user.goals.build(goal_params)
    @goal.total_saved = 0 if @goal.total_saved.blank?

    if @goal.save
      redirect_to habit_saver_root_path, notice: "Goal created."
      return
    end

    load_dashboard_data
    initialize_dashboard_forms(goal: @goal)
    flash.now[:alert] = @goal.errors.full_messages.to_sentence
    render "habit_saver/dashboard", status: :unprocessable_entity
  end

  private

  def goal_params
    params.require(:goal).permit(:name, :target_amount, :daily_earnings_cap)
  end
end
