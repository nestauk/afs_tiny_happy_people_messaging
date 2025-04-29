class SendCustomMessageJob < ApplicationJob
  queue_as :background

  def perform(message)
    Twilio::Client.new.send_message(message)
  end
end
