class SurveysController < ApplicationController
  before_action :set_survey, only: [:edit, :update]
  before_action :set_user, :set_questions, :set_answers, only: [:edit]

  def edit
  end

  def update
    if @survey.update(survey_params)
      redirect_to thank_you_users_path, notice: "Thank you for completing the survey!"
    else
      set_user
      @questions = @survey.questions.sort_by(&:position)
      set_answers
      render :edit
    end
  end

  private

  def set_survey
    @survey = Survey.find(params[:id])
  end

  def set_questions
    @questions = @survey.questions.includes(:answers).order(:position)
  end

  def set_user
    @user = User.find_by_token_for(:survey_token, params[:token])
    unless @user
      redirect_to root_path, alert: "Invalid survey link."
    end
  end

  def set_answers
    @questions.each do |question|
      question.answers.load unless question.answers.loaded?
      question.answers.target.select! { |a| a.user_id == @user.id }
      question.answers.build(user: @user) if question.answers.none?
    end
  end

  def survey_params
    params.require(:survey).permit(
      questions_attributes: [
        :id,
        answers_attributes: [:id, :question_id, :user_id, :response, {response: []}],
      ],
    )
  end
end
