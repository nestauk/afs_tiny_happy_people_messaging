class RestartMessagesJob < ApplicationJob
  queue_as :background

  def perform(user)
    Appsignal::CheckIn.cron("restart_messages_job") do
      if user.update(contactable: true, restart_at: nil)
        message = Message.build(user: user, body: "Welcome back to Tiny Happy People! Text 'END' to unsubscribe at any time.")
        SendCustomMessageJob.perform_later(message) if message.save
      end
    end
  end
end
