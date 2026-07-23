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
      statistical: parsed["statistical"] == true
    )
  rescue JSON::ParserError
    new(decided: false)
  end

  def self.accept_all
    new(decided: true, analytics: true, marketing: true, statistical: true)
  end

  def self.reject_all
    new(decided: true, analytics: false, marketing: false, statistical: false)
  end

  def self.from_params(params)
    boolean = ActiveModel::Type::Boolean.new
    new(
      decided: true,
      analytics: boolean.cast(params[:analytics]) || false,
      marketing: boolean.cast(params[:marketing]) || false,
      statistical: boolean.cast(params[:statistical]) || false
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
