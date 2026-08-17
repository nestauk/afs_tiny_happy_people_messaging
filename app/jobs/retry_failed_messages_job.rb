class RetryFailedMessagesJob < ApplicationJob
  queue_as :background

  def perform
    Message.joins(:user)
      .merge(User.where(anonymised_at: nil, contactable: true))
      .where(status: "failed", created_at: 1.hour.ago..)
      .preload(:user)
      .find_each do |message|
        Sms::Client.new(message).send_message
      rescue => e
        Appsignal.report_error(e) do
          Appsignal.add_tags(message_id: message.id, user_id: message.user_id)
        end
      end
  end
end
