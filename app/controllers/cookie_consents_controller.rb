class CookieConsentsController < ApplicationController
  skip_before_action :authenticate_admin!
  skip_before_action :track_ahoy_visit, only: [:create]

  def create
    consent = build_consent
    return_to = params[:return_to].presence || request.referer || root_path

    cookies[CookieConsent::COOKIE_NAME] = {
      value: consent.to_cookie_value,
      expires: 1.year,
      secure: true,
      same_site: :lax,
    }

    apply_statistical(consent)
    apply_marketing(consent)
    track(consent, return_to)
    flash[:cookie_consent_result] = result_key

    redirect_to return_to
  end

  private

  # ahoy.rb's exclude_method checks this cookie directly, independent of the
  # cookie_consent cookie, so it has to be kept in sync whenever statistical
  # consent changes.
  def apply_statistical(consent)
    if consent.statistical?
      cookies.delete(:ahoy_dnt)
    else
      cookies[:ahoy_dnt] = {value: "1", expires: 1.year, secure: true, same_site: :lax}
    end
  end

  MARKETING_COOKIES = %w[_rdt_uuid _ttp _tt_enable_cookie _fbp].freeze

  # The marketing pixels themselves only load once consent.marketing? is true
  # (see _cookie_banner.html.erb), but on decline we also proactively clear
  # any cookies they may have already set on a previous visit.
  def apply_marketing(consent)
    return if consent.marketing?

    domain = ".#{request.host.sub(/\Awww\./, "")}"
    MARKETING_COOKIES.each { |name| cookies.delete(name, domain: domain) }
  end

  def build_consent
    case params[:decision]
    when "accept_all" then CookieConsent.accept_all
    when "reject_all" then CookieConsent.reject_all
    else CookieConsent.from_params(params)
    end
  end

  def result_key
    case params[:decision]
    when "accept_all" then "accepted"
    when "reject_all" then "rejected"
    else "saved"
    end
  end

  def track(consent, page)
    return unless ahoy.visit.present?

    CookieConsent::CATEGORIES.each do |category|
      decision = consent.public_send("#{category}?") ? "accepted" : "declined"
      ahoy.track "cookie_consent", page: page, category: category.to_s, decision: decision
    end
  end
end
