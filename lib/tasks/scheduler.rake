namespace :scheduler do
  desc "Send morning text message"
  task send_morning_message: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_MESSAGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.wants_morning_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a)
    end
  end

  desc "Send afternoon text message"
  task send_afternoon_message: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_MESSAGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.wants_afternoon_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a)
    end
  end

  desc "Send evening text message"
  task send_evening_message: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_MESSAGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.wants_evening_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a)
    end
  end

  desc "Send no timing preference text message"
  task send_no_timing_preference_message: :environment do
    (next unless Date.today.wday == ENV.fetch("WEEKLY_MESSAGE_DAY").to_i) if ENV.fetch("SET_WEEKLY") == "true"

    User.contactable.no_preference_message.find_in_batches do |users|
      SendBulkMessageJob.perform_later(users.to_a)
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

    User.contactable.not_nudged.not_clicked_last_two_messages.each do |user|
      message = Message.create(user:, body: "You've not interacted with any videos lately. Want to continue receiving them? You can text 'PAUSE' for a break, 'ADJUST' for different content, or 'STOP' to stop them entirely.")
      SendCustomMessageJob.perform_later(message)
      user.update(nudged_at: Time.now)
    end
  end
end
