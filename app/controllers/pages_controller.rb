class PagesController < ApplicationController
  skip_before_action :authenticate_admin!

  def privacy_policy
  end

  def terms
  end

  def thank_you
  end

  def resources
  end
end
