class SendBulkMessageJob < ApplicationJob
  queue_as :default

  def perform(users, group)
    return unless group.present?

    message_jobs = users.map { |user| SendMessageJob.new(user, group) }

    ActiveJob.perform_all_later(message_jobs)
  end
end
