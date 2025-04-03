namespace :scheduler do
  desc "Send morning text message"
  task send_morning_message: :environment do
    User.contactable.with_preference_for_day(Date.today.wday).wants_morning_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :weekly_message)
    end
  end

  desc "Send afternoon text message"
  task send_afternoon_message: :environment do
    User.contactable.with_preference_for_day(Date.today.wday).wants_afternoon_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :weekly_message)
    end
  end

  desc "Send evening text message"
  task send_evening_message: :environment do
    User.contactable.with_preference_for_day(Date.today.wday).wants_evening_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :weekly_message)
    end
  end

  desc "Send no timing preference text message"
  task send_no_timing_preference_message: :environment do
    # Users with no day preference get automatically set to Tuesdays
    User.contactable.with_preference_for_day(Date.today.wday).no_hour_preference_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :weekly_message)
    end
  end

  desc "Restart users who paused"
  task restart_users: :environment do
    User.opted_out.where("restart_at < ?", Time.now).each do |user|
      user.update(contactable: true, restart_at: nil)
      RestartMessagesJob.perform_later(user)
    end
  end

  desc "Check for disengaged users"
  task check_for_disengaged_users: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_NUDGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.not_nudged.not_clicked_last_x_messages(3).each do |user|
      message = Message.create(user:, body: "You've not interacted with any videos lately. You can text 'PAUSE' for a break or 'END' to stop them entirely.")
      SendCustomMessageJob.perform_later(message)
      user.update(nudged_at: Time.now)
    end
  end

  desc "Update local authority data"
  task update_local_authority_data: :environment do
    AllLasDashboard.refresh
    LaSpecificDashboard.refresh
  end

  desc "Get user feedback"
  task get_user_feedback: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_NUDGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.received_two_messages.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :feedback)
    end
  end

  desc "Send survey (not permanent)"
  task send_survey: :environment do
    User.contactable.order(:created_at).first(101).find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a, :survey)
    end
  end
end
