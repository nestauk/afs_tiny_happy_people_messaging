class Admin::QuestionsController < ApplicationController
  before_action :check_admin_role
  before_action :set_survey, :set_survey_section
  before_action :set_question, only: [:show, :edit, :update, :destroy, :update_position]

  def show
  end

  def new
    @question = @survey_section.questions.new
  end

  def create
    @question = @survey_section.questions.new(question_params)
    if @question.save
      redirect_to admin_survey_path(@survey), notice: "Question was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @question.update(question_params)
      redirect_to admin_survey_path(@survey), notice: "Question was successfully updated."
    else
      render :edit
    end
  end

  def update_position
    @question.update(position: params[:position])
    head :no_content
  end

  def destroy
    if @question.destroy
      redirect_to admin_survey_path(@survey), notice: "Question was successfully deleted.", status: :see_other
    else
      redirect_to admin_survey_path(@survey), alert: "Failed to delete question.", status: :see_other
    end
  end

  private

  def set_survey
    @survey = Survey.find(params[:survey_id])
  end

  def set_survey_section
    @survey_section = SurveySection.find(params[:survey_section_id])
  end

  def set_question
    @question = @survey_section.questions.find(params[:id])
  end

  def question_params
    permitted = params.require(:question).permit(
      :text_en, :text_cy, :survey_section_id, :position, :hint_en, :hint_cy,
      :question_type, :options_text_en, :options_text_cy
    )

    options_en = permitted.delete(:options_text_en).to_s.split("\n").map(&:strip).reject(&:empty?)
    options_cy = permitted.delete(:options_text_cy).to_s.split("\n").map(&:strip).reject(&:empty?)
    permitted.merge(options_en:, options_cy:)
  end
end
