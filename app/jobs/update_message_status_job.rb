class UpdateMessageStatusJob < ApplicationJob
  queue_as :background

  def perform(message_sid:, status:)
    message = Message.find_by(message_sid:)

    return if message.nil?

    message.update(status:)
  end
end
