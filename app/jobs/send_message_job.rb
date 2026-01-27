class SendMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :real_time

  def perform(user)
    # If BulkMessage fails and reruns this job, don't send them the next message
    return if user.had_content_this_week?

    content = user.next_content
    return if content.blank?

    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.link = content.link
      m.user = user
      m.body = substitute_variables(content.body, m)
      m.content = content
    end

    Twilio::Client.new.send_message(message) if save_user_and_message(user, message, content)
  end

  private

  def save_user_and_message(user, message, content)
    ActiveRecord::Base.transaction do
      user.update!(last_content_id: content.id)
      message.save!
    rescue ActiveRecord::RecordInvalid => e
      Appsignal.report_error(e) do
        Appsignal.add_tags(user_info: user.attributes, message_info: message.attributes)
      end

      false
    end
  end

  def substitute_variables(content, message)
    translations = {
      "{{parent_name}}": message.user.first_name,
      "{{child_name}}": message.user.child_name.presence || I18n.t("messages.your_child", locale: message.user.language || I18n.default_locale),
      "{{link}}": track_link_url(message.token),
    }

    content.gsub(/({{parent_name}}|{{child_name}}|{{link}})/) do |match|
      translations[match.to_sym]
    end
  end
end
