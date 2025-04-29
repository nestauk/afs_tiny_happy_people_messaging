class SendBulkMessageJob < ApplicationJob
  queue_as :real_time

  def perform(users, message_type)
    message_jobs = if message_type == :feedback
      users.map { |user| SendFeedbackMessageJob.new(user) }
    elsif message_type == :weekly_message
      users.map { |user| SendMessageJob.new(user) }
    end

    ActiveJob.perform_all_later(message_jobs) unless message_jobs.nil?
  end
end
