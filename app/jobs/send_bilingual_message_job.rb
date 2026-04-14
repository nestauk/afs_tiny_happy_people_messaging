class SendBilingualMessageJob < ApplicationJob
  include MessageVariableSubstitution
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = substitute_variables(
        I18n.t(".messages.bilingual_text", locale: user.language || I18n.default_locale),
        user, token: m.token
      )
      m.link = "https://www.bbc.co.uk/tiny-happy-people/articles/ztrj4xs"
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(sent_bilingual_text_at: Time.zone.now)
    end
  end
end
