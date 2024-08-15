namespace :scheduler do
  desc "Send text message"
  task send_message: :environment do
    User.all.each do |user|
      Delayed::Job.enqueue SendMesssageJob.new(user)
    end
  end
end
