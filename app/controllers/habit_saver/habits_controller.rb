class HabitSaver::HabitsController < ApplicationController
  include HabitSaverControllerSupport

  before_action :require_habit_saver_user


  def create
    @habit_saver_user = current_habit_saver_user
    @habit = @habit_saver_user.habits.build(habit_params)

    if @habit.save
      redirect_to habit_saver_root_path, notice: "Habit created."
      return
    end

    load_dashboard_data
    initialize_dashboard_forms(habit: @habit)
    flash.now[:alert] = @habit.errors.full_messages.to_sentence
    render "habit_saver/dashboard", status: :unprocessable_entity
  end


  private

  def habit_params
    params.require(:habit).permit(:name, :target_per_unit, :time_unit)
  end
  
end