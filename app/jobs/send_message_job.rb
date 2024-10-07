class SendMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user, group)
    content = user.next_content(group)

    return unless content.present?
    # If BulkMessage fails and reruns this job, don't send them the next message
    return if user.had_content_this_week?

    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.link = content.link
      m.user = user
      m.body = content.body.gsub("{{link}}", track_link_url(m.token))
      m.content = content
    end

    Twilio::Client.new.send_message(message) if message.save
  end
end
