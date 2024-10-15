class PagesController < ApplicationController
  skip_before_action :authenticate_admin!

  def privacy_policy
  end

  def terms
  end

  def thank_you
  end

  def resources
    Page.find_by(name: "resources").clicks.create if Rails.env.production?
  end
end
