class SendBulkMessageJob < ApplicationJob
  queue_as :default

  def perform(users)
    message_jobs = users.map { |user| SendMessageJob.new(user) }

    message_jobs.each do |job|
      job.perform_now
    end
  end
end
