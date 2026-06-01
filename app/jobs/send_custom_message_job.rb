class SendCustomMessageJob < ApplicationJob
  queue_as :background

  def perform(message)
    Sms::Client.new(message).send_message
  end
end
