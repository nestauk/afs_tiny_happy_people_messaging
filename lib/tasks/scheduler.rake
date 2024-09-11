namespace :scheduler do
  desc "Send text message"
  task send_message: :environment do
    User.contactable.each do |user|
      SendMessageJob.perform_later(user: user)
    end
  end
end
