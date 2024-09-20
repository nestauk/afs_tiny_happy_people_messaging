class SendCustomMessageJob < ApplicationJob
  queue_as :default

  def perform(user, body)
    return unless body.present?

    message = Message.create(user:, body:)

    Twilio::Client.new.send_message(message)
  end
end
