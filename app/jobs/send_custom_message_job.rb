class SendCustomMessageJob < ApplicationJob
  queue_as :default

  def perform(message)
    Twilio::Client.new.send_message(message)
  end
end
