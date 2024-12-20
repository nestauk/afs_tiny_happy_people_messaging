class MessagesController < ApplicationController
  skip_before_action :authenticate_admin!, only: [:status, :incoming, :next]
  skip_before_action :verify_authenticity_token, only: [:status, :incoming]

  def index
    @messages = Message.all
  end

  def status
    if valid_twilio_request?(request)
      message_sid = params["MessageSid"]
      status = params["MessageStatus"]

      Message.find_by(message_sid:).update(status:)
    end
  end

  def incoming
    if valid_twilio_request?(request)
      user = User.find_by(phone_number: params["From"])
      Message.create(user:, body: params["Body"], message_sid: params["MessageSid"], status: "received")
    end
  end

  def next
    @message = Message.find_by(token: params[:token])

    @message.update(clicked_at: Time.now)

    redirect_to @message.link, allow_other_host: true
  end

  def new
    @user = User.find(params[:user_id])
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      SendCustomMessageJob.perform_later(@message)

      redirect_to user_path(@message.user), notice: "Message sent!"
    else
      render :new
    end
  end

  private

  def message_params
    params.require(:message).permit(:user_id, :body)
  end

  def valid_twilio_request?(request)
    validator = Twilio::Security::RequestValidator.new(ENV["TWILIO_AUTH_TOKEN"])
    url = request.url # Full URL of the incoming request

    # Collect request parameters, which may be in POST body or query string
    params = request.POST.to_h

    # Get the X-Twilio-Signature header
    twilio_signature = request.headers["X-Twilio-Signature"]

    # Validate the request using the Twilio helper
    validator.validate(url, params, twilio_signature)
  end
end
