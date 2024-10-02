namespace :scheduler do
  desc "Send morning text message"
  task send_morning_message: :environment do
    User.contactable.wants_morning_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      users.each do |user|
        SendMessageJob.perform_later(user, group)
      end
    end
  end

  desc "Send afternoon text message"
  task send_afternoon_message: :environment do
    User.contactable.wants_afternoon_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      users.each do |user|
        SendMessageJob.perform_later(user, group)
      end
    end
  end

  desc "Send evening text message"
  task send_evening_message: :environment do
    User.contactable.wants_evening_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      users.each do |user|
        SendMessageJob.perform_later(user, group)
      end
    end
  end

  desc "Send no timing preference text message"
  task send_no_timing_preference_message: :environment do
    User.contactable.no_preference_message.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      users.each do |user|
        SendMessageJob.perform_later(user, group)
      end
    end
  end
end
