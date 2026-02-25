class SendBulkMessageJob < ApplicationJob
  queue_as :real_time

  def perform(message_type, time = nil)
    case message_type
    when "weekly_message"
      Appsignal::CheckIn.cron("send_#{time}_job") do
        jobs = users_for(time).map { |user| SendMessageJob.new(user) }
        ActiveJob.perform_all_later(jobs) if jobs.any?
      end
    when "feedback"
      Appsignal::CheckIn.cron("send_feedback_message_job") do
        jobs = User.contactable.received_two_messages.map { |user| SendFeedbackMessageJob.new(user) }
        ActiveJob.perform_all_later(jobs) if jobs.any?
      end
    when "nudge"
      Appsignal::CheckIn.cron("nudge_users_job") do
        jobs = User.contactable.not_nudged.not_clicked_last_x_messages(3).map { |user| NudgeUsersJob.new(user) }
        ActiveJob.perform_all_later(jobs) if jobs.any?
      end
    when "restart"
      Appsignal::CheckIn.cron("restart_messages_job") do
        jobs = User.due_for_restart.map { |user| RestartMessagesJob.new(user) }
        ActiveJob.perform_all_later(jobs) if jobs.any?
      end
    end
  end

  private

  def users_for(time)
    base = User.not_finished_content.contactable.with_preference_for_day(Time.zone.today.wday)
    case time
    when "morning" then base.wants_morning_message
    when "afternoon" then base.wants_afternoon_message
    when "evening" then base.wants_evening_message
    when "no_preference" then base.no_hour_preference_message
    end
  end
end
