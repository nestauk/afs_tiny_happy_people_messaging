class ApplicationController < ActionController::Base
  before_action :authenticate_admin!
  around_action :switch_locale
  before_action :apply_skadi_consent

  include Skadi::Analytics

  def switch_locale(&action)
    locale = extract_locale_from_params || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def after_sign_in_path_for(resource)
    dashboard_admin_users_path
  end

  private

  def check_admin_role
    redirect_to root_path unless current_admin.role == "admin"
  end

  def admin_role?
    current_admin.role == "admin"
  end

  # Skadi is a first-party behavioural tracker so it's gated by the same "statistical" consent category
  def apply_skadi_consent
    skadi.do_not_track! unless CookieConsent.from_cookie(cookies[CookieConsent::COOKIE_NAME]).statistical?
  end

  def extract_locale_from_params
    parsed_locale = params[:locale].to_s
    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
  end
end
