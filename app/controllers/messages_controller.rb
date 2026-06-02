class MessagesController < ApplicationController
  skip_before_action :authenticate_admin!, only: [:status, :incoming, :next]
  skip_before_action :verify_authenticity_token, only: [:status, :incoming]
  before_action :verify_twilio_request, only: [:status, :incoming]

  ALLOWED_HOSTS = %w[bbc.co.uk www.bbc.co.uk].freeze

  def status
    if twilio_message_params[:MessageStatus] == "failed"
      Appsignal.report_error(StandardError.new("Twilio message failed")) do
        Appsignal.add_tags(twilio_message_params: twilio_message_params)
      end

      UpdateMessageStatusJob.perform_later(twilio_message_params)
    end

    head :no_content
  end

  def incoming
    user = User.find_by(phone_number: params["From"])
    Message.create(user:, body: params["Body"], message_sid: params["MessageSid"], status: "received")

    head :no_content unless user
  end

  def next
    message = Message.find_by(token: params[:token])
    url = safe_link(message&.link) || "https://www.bbc.co.uk/tiny-happy-people"
    message&.update(clicked_at: Time.zone.now)
    redirect_to url, allow_other_host: true
  end

  private

  def safe_link(url)
    return nil if url.blank?
    uri = URI.parse(url)
    ALLOWED_HOSTS.include?(uri.host) ? url : nil
  rescue URI::InvalidURIError
    nil
  end

  def twilio_message_params
    params.permit(:MessageSid, :MessageStatus, :From, :To, :Body)
  end

  def verify_twilio_request
    if ENV["TWILIO_AUTH_TOKEN"].blank?
      Appsignal.report_error(StandardError.new("Twilio webhook received but TWILIO_AUTH_TOKEN is not configured"))
      head :forbidden
      return
    end

    unless valid_twilio_request?(request)
      head :forbidden
    end
  end

  def valid_twilio_request?(request)
    validator = Twilio::Security::RequestValidator.new(ENV["TWILIO_AUTH_TOKEN"])
    validator.validate(request.url, request.POST.to_h, request.headers["X-Twilio-Signature"])
  end
end
