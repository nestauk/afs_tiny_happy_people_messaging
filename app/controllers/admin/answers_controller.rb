class Admin::AnswersController < ApplicationController
  before_action :check_admin_role
  before_action :set_survey
  after_action :do_not_track!

  def index
  end

  private

  def set_survey
    @survey = Survey.find(params[:survey_id])
  end
end
