class Admin::QuestionsController < ApplicationController
  before_action :check_admin_role
  before_action :set_survey
  before_action :set_question, only: [:show, :edit, :update, :destroy, :update_position]

  def show
  end

  def new
    @question = @survey.questions.new
  end

  def create
    @question = @survey.questions.new(question_params)
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
      redirect_to admin_survey_path(@survey), notice: "Question was successfully deleted."
    else
      redirect_to admin_survey_path(@survey), alert: "Failed to delete question."
    end
  end

  private

  def set_survey
    @survey = Survey.find(params[:survey_id])
  end

  def set_question
    @question = @survey.questions.find(params[:id])
  end

  def question_params
    permitted = params.require(:question).permit(:text_en, :text_cy, :position, :question_type, :options_text_en, :options_text_cy)
    options_en = permitted.delete(:options_text_en).to_s.split("\n").map(&:strip).reject(&:empty?)
    options_cy = permitted.delete(:options_text_cy).to_s.split("\n").map(&:strip).reject(&:empty?)
    permitted.merge(options_en:, options_cy:)
  end
end
