class SendFeedbackMessageJob < ApplicationJob
  queue_as :default

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = "Are the activities we send you suitable for your child? Respond Yes or No to let us know."
    end

    Twilio::Client.new.send_message(message) if message.save
  end
end
