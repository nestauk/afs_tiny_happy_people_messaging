class PagesController < ApplicationController
  skip_before_action :authenticate_admin!

  def privacy_policy
  end

  def terms
  end

  def about_us
  end

  def resources
    Page.find_or_create_by(name: "resources").clicks.create if Rails.env.production?
  end

  def diary_study
  end
end
