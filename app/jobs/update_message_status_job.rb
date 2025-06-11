class UpdateMessageStatusJob < ApplicationJob
  queue_as :background

  def perform(params)
    message_sid = params[:MessageSid]
    status = params[:MessageStatus]

    message = Message.find_by(message_sid:)

    return if message.nil?

    message.update(status:)
  end
end
