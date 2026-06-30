class CookieConsentsController < ApplicationController
  skip_before_action :authenticate_admin!

  def create
    category = params[:category].to_s
    decision = params[:decision].to_s
    page = params[:page].to_s

    if %w[analytics marketing statistical].include?(category) && %w[accepted declined].include?(decision)
      ahoy.track "cookie_consent", page: page, category: category, decision: decision
    end

    head :no_content
  end
end
