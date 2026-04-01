class Admin::SurveysController < ApplicationController
  before_action :check_admin_role
  before_action :set_survey, only: [:show, :edit, :update, :destroy]

  def index
    @surveys = Survey.all
  end

  def show
  end

  def new
    @survey = Survey.new
  end

  def create
    @survey = Survey.new(survey_params)
    if @survey.save
      redirect_to admin_surveys_path, notice: "Survey was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @survey.update(survey_params)
      redirect_to admin_survey_path(@survey), notice: "Survey was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @survey.destroy
    redirect_to admin_surveys_path, notice: "Survey was successfully deleted."
  end

  private

  def set_survey
    @survey = Survey.find(params[:id])
  end

  def survey_params
    params.require(:survey).permit(:title_en, :title_cy, :send_after_message_count, :send_on_last_message)
  end
end
