class PagesController < ApplicationController
  skip_before_action :authenticate_admin!
  before_action :set_page_variables
  after_action :track_action

  def privacy_policy
  end

  def terms
  end

  def about_us
  end

  def resources
  end

  def diary_study
  end

  private

  def track_action
    ahoy.track request.path_parameters[:action], request.path_parameters
  end

  def set_page_variables
    @hide_sidebar = true
    @show_footer = true
  end
end
