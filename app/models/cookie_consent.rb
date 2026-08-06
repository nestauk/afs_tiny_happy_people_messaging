class CookieConsent
  COOKIE_NAME = "cookie_consent"
  CATEGORIES = %i[analytics marketing statistical].freeze

  attr_reader :analytics, :marketing, :statistical

  def self.from_cookie(raw)
    return new(decided: false) if raw.blank?

    parsed = JSON.parse(raw)
    new(
      decided: true,
      analytics: parsed["analytics"] == true,
      marketing: parsed["marketing"] == true,
      statistical: parsed["statistical"] == true,
    )
  rescue JSON::ParserError => e
    Appsignal.report_error(e)
    new(decided: false)
  end

  def self.accept_all
    new(decided: true, analytics: true, marketing: true, statistical: true)
  end

  def self.reject_all
    new(decided: true, analytics: false, marketing: false, statistical: false)
  end

  def self.from_params(params)
    new(
      decided: true,
      analytics: params[:analytics] == "1",
      marketing: params[:marketing] == "1",
      statistical: params[:statistical] == "1",
    )
  end

  def initialize(decided:, analytics: false, marketing: false, statistical: false)
    @decided = decided
    @analytics = analytics
    @marketing = marketing
    @statistical = statistical
  end

  def decided?
    @decided
  end

  def analytics?
    analytics
  end

  def marketing?
    marketing
  end

  def statistical?
    statistical
  end

  def to_cookie_value
    {analytics: analytics, marketing: marketing, statistical: statistical}.to_json
  end
end
