namespace :scheduler do
  desc "Send morning text message"
  task send_morning_message: :environment do
    User.contactable.wants_morning_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      SendBulkMessageJob.perform_later(users, group)
    end
  end

  desc "Send afternoon text message"
  task send_afternoon_message: :environment do
    User.contactable.wants_afternoon_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      SendBulkMessageJob.perform_later(users, group)
    end
  end

  desc "Send evening text message"
  task send_evening_message: :environment do
    User.contactable.wants_evening_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      SendBulkMessageJob.perform_later(users, group)
    end
  end

  desc "Send no timing preference text message"
  task send_no_timing_preference_message: :environment do
    User.contactable.no_preference_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      SendBulkMessageJob.perform_later(users, group)
    end
  end

  desc "Restart users who paused"
  task restart_users: :environment do
    User.where(contactable: false).where("restart_at < ?", Time.now).each do |user|
      user.update(contactable: true, restart_at: nil)
      RestartMessagesJob.perform_later(user)
    end
  end

  desc "Check for disengaged users"
  task check_for_disengaged_users: :environment do
    User.contactable.not_clicked_last_two_messages.each do |user|
      message = Message.create(user:, body: "Hey are you ok?")
      SendCustomMessageJob.perform_later(message)
    end
  end
end
