class CookieConsentsController < ApplicationController
  skip_before_action :authenticate_admin!

  def create
    category = params[:category].to_s
    decision = params[:decision].to_s

    if %w[analytics marketing].include?(category) && %w[accepted declined].include?(decision)
      ahoy.track "cookie_consent", category: category, decision: decision
    end

    head :no_content
  end
end
