class SendBilingualMessageJob < ApplicationJob
  include MessageVariableSubstitution

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = substitute_variables(
        I18n.t(".messages.bilingual_text", locale: user.language || I18n.default_locale),
        user,
      )
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      user.update(sent_bilingual_text_at: Time.zone.now)
    end
  end
end
