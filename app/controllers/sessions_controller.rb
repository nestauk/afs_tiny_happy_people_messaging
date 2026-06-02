class SessionsController < Devise::Passwordless::SessionsController
  rate_limit to: 3, within: 5.minutes, by: -> { request.ip }, only: :create, with: -> { rate_limit_exceeded }

  def new
    super
  end

  def create
    super
  end

  private

  def rate_limit_exceeded
    @user = User.new
    @no_padding = true
    @hide_sidebar = true

    flash.now[:notice] = I18n.t("controllers.users.rate_limit_exceeded.notice")
    redirect_to root_path, alert: I18n.t("controllers.users.rate_limit_exceeded.alert")
  end
end
