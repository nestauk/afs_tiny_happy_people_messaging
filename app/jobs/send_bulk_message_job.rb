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
    end

    ActiveJob.perform_all_later(message_jobs) unless message_jobs.nil?
  end

  private 

  def set_users(time)
    if time == "morning"
      User.not_finished_content.contactable.with_preference_for_day(Date.today.wday).wants_morning_message
    elsif time == "afternoon"
      User.not_finished_content.contactable.with_preference_for_day(Date.today.wday).wants_afternoon_message
    elsif time == "evening"
      User.not_finished_content.contactable.with_preference_for_day(Date.today.wday).wants_evening_message
    elsif time == "no_preference"
      User.not_finished_content.contactable.with_preference_for_day(Date.today.wday).no_hour_preference_message
    end
  end
end
