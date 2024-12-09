class SendBulkMessageJob < ApplicationJob
  queue_as :default

  def perform(users)
    message_jobs = users.map { |user| SendMessageJob.new(user) }

    ActiveJob.perform_all_later(message_jobs)
  end
end
