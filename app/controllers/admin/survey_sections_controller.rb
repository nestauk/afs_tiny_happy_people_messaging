class Admin::SurveySectionsController < ApplicationController
  before_action :check_admin_role
  before_action :set_survey
  before_action :set_survey_section, only: [:edit, :update, :destroy]

  def index
    @survey_sections = @survey.survey_sections
  end

  def show
  end

  def new
    @survey_section = @survey.survey_sections.new
  end

  def create
    @survey_section = @survey.survey_sections.new(survey_section_params)
    if @survey_section.save!
      redirect_to admin_survey_path(@survey), notice: "Survey was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @survey_section = @survey.survey_sections.find(params[:id])
  end

  def update
    if @survey_section.update(survey_section_params)
      redirect_to admin_survey_path(@survey), notice: "Survey was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @survey_section.destroy
    redirect_to admin_surveys_path, notice: "Survey was successfully deleted."
  end

  private

  def set_survey
    @survey = Survey.find(params[:survey_id])
  end

  def set_survey_section
    @survey_section = @survey.survey_sections.find(params[:id])
  end

  def survey_section_params
    params.require(:survey_section).permit(
      :title_en, :title_cy, :position
    )
  end
end
