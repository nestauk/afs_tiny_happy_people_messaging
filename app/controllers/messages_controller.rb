class MessagesController < ApplicationController
  skip_before_action :authenticate_admin!, only: [:twilio_status, :twilio_incoming, :aws_status, :aws_incoming, :next]
  skip_before_action :verify_authenticity_token, only: [:twilio_status, :twilio_incoming, :aws_status, :aws_incoming]
  before_action :verify_twilio_request, only: [:twilio_status, :twilio_incoming]
  before_action :verify_sns_request, only: [:aws_status, :aws_incoming]

  ALLOWED_HOSTS = %w[bbc.co.uk www.bbc.co.uk].freeze

  def twilio_status
    if twilio_message_params[:MessageStatus] == "failed"
      Appsignal.report_error(StandardError.new("Twilio message failed")) do
        Appsignal.add_tags(twilio_message_params: twilio_message_params)
      end

      UpdateMessageStatusJob.perform_later(message_sid: twilio_message_params[:MessageSid], status: "failed")
    end

    head :no_content
  end

  def twilio_incoming
    user = User.find_by(phone_number: params["From"])
    Message.create(user:, body: params["Body"], message_sid: params["MessageSid"], status: "received")

    head :no_content unless user
  end

  def aws_status
    return head :ok if handle_sns_subscription(sns_envelope)

    event = sns_event

    if Sms::AwsAdapter::AWS_FAILED_EVENT_TYPES.include?(event["eventType"])
      Appsignal.report_error(StandardError.new("AWS SMS delivery failed")) do
        Appsignal.add_tags(aws_event: event)
      end

      UpdateMessageStatusJob.perform_later(message_sid: event["messageId"], status: "failed")
    end

    head :no_content
  end

  def aws_incoming
    return head :ok if handle_sns_subscription(sns_envelope)

    event = sns_event
    user = User.find_by(phone_number: event["originationNumber"])
    Message.create(user:, body: event["messageBody"], message_sid: event["inboundMessageId"], status: "received")

    head :no_content
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

  def sns_envelope
    @sns_envelope ||= JSON.parse(request.raw_post)
  end

  def sns_event
    @sns_event ||= JSON.parse(sns_envelope["Message"])
  end

  def verify_sns_request
    Aws::SNS::MessageVerifier.new.authenticate!(request.raw_post)
  rescue Aws::SNS::MessageVerifier::VerificationError, JSON::ParserError => e
    Appsignal.report_error(e)
    head :forbidden
  end

  def handle_sns_subscription(envelope)
    case envelope["Type"]
    when "SubscriptionConfirmation"
      Rails.logger.warn("SNS subscription pending for topic #{envelope["TopicArn"]} — visit #{envelope["SubscribeURL"]} to confirm")
      true
    when "UnsubscribeConfirmation"
      true
    else
      false
    end
  end
end
