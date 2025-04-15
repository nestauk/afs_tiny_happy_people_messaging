class ApplicationController < ActionController::Base
  before_action :authenticate_admin!
  around_action :switch_locale

  def switch_locale(&action)
    locale = extract_locale_from_params || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    {locale: I18n.locale}
  end

  def after_sign_in_path_for(resource)
    if resource.role == "local_authority"
      admin_dashboard_path
    elsif resource.role == "admin"
      dashboard_admin_users_path
    end
  end

  def check_admin_role
    redirect_to root_path unless current_admin.role == "admin"
  end

  private

  def extract_locale_from_params
    parsed_locale = params[:locale].to_s
    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
  end
end
