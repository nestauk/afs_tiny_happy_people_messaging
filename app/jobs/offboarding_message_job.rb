class OffboardingMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = I18n.t(".messages.offboarding", locale: user.language || I18n.default_locale)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
    end
  end
end
