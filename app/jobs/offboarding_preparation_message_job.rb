class OffboardingPreparationMessageJob < ApplicationJob
  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = I18n.t(".messages.offboarding_preparation", locale: user.language || I18n.default_locale)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
    else
      Appsignal.report_error(StandardError.new("Failed to send offboarding preparation message")) do
        Appsignal.add_tags(user_id: user.id, errors: message.errors.full_messages)
      end
    end
  end
end
