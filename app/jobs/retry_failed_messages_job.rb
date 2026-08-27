class RetryFailedMessagesJob < ApplicationJob
  queue_as :background

  def perform
    messages = Message.joins(:user)
      .merge(User.where(anonymised_at: nil, contactable: true))
      .where(status: "failed", created_at: 1.hour.ago..)
      .preload(:user)
      .order(:id)
      .to_a

    messages.each_slice(Sms::Client::BATCH_SIZE).with_index do |batch, index|
      sleep(1) unless index.zero?

      batch.each do |message|
        Sms::Client.new(message).send_message
      rescue => e
        Appsignal.report_error(e) do
          Appsignal.add_tags(message_id: message.id, user_id: message.user_id)
        end
      end
    end
  end
end
