namespace :scheduler do
  desc "Send text message"
  task send_message: :environment do
    User.contactable.group_by(&:child_age_in_months_today).each do |age, users|
      group = Group.find_by(age_in_months: age)

      next unless group

      users.each do |user|
        SendMessageJob.perform_later(user, group)
      end
    end
  end
end
