class SendWelcomeMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = substitute_variables(I18n.t(".messages.welcome", locale: user.language || I18n.default_locale), user)
    end

    Twilio::Client.new.send_message(message) if message.save
  end

  private

  def substitute_variables(content, user)
    translations = {
      "{{parent_name}}": user.first_name,
      "{{child_name}}": user.child_name.presence || I18n.t("messages.your_child", locale: user.language || I18n.default_locale),
    }

    content.gsub(/({{parent_name}}|{{child_name}})/) do |match|
      translations[match.to_sym]
    end
  end
end
