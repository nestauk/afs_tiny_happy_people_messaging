class DiaryEntriesController < ApplicationController
  skip_before_action :authenticate_admin!
  before_action :set_user

  def new
    @diary_entry_form = DiaryEntryForm.new(@user, params, session)
  end

  def create
    @diary_entry_form = DiaryEntryForm.new(@user, params, session)

    persist_arrays_to_session

    if @diary_entry_form.save
      redirect_to user_diary_entry_path(user_id: @user.id, id: @user.diary_entries.last)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @no_padding = true
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def persist_arrays_to_session
    if @diary_entry_form.stage == "this_week"
      session[:days] = @diary_entry_form.days
      session[:timings] = @diary_entry_form.timings
    end

    if @diary_entry_form.stage == "feedback"
      session[:feedback] = @diary_entry_form.feedback
    end
  end
end
