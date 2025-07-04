class SendBulkMessageJob < ApplicationJob
  queue_as :real_time

  def perform(message_type, time = nil)
    message_jobs = case message_type
    when "feedback"
      users = User.contactable.received_two_messages
      users.map { |user| SendFeedbackMessageJob.new(user) }
    when "weekly_message"
      users = set_users(time)
      users.map { |user| SendMessageJob.new(user) }
    when "nudge"
      users = User.contactable.not_nudged.not_clicked_last_x_messages(3)
      users.map { |user| NudgeUsersJob.new(user) }
    when "restart"
      users = User.opted_out.where("restart_at < ?", Time.now)
      users.map { |user| RestartMessagesJob.new(user) }
    when "check_adjustment"
      users = User.contactable.where("last_adjustment_check < ?", 1.week.ago)
      users.map { |user| CheckAdjustmentJob.new(user) }
    end

    return if message_jobs.nil? || message_jobs.empty?

    ActiveJob.perform_all_later(message_jobs)
  end

  private

  def set_users(time)
    users = User.not_finished_content.contactable.with_preference_for_day(Date.today.wday)

    if time == "morning"
      users.wants_morning_message
    elsif time == "afternoon"
      users.wants_afternoon_message
    elsif time == "evening"
      users.wants_evening_message
    elsif time == "no_preference"
      users.no_hour_preference_message
    end
  end
end
