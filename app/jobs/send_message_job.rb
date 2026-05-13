class SendMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :real_time

  def perform(user)
    # If BulkMessage fails and reruns this job, don't send them the next message
    return if user.had_content_this_week?
    return if user.finished_programme?

    content = user.next_content
    return if content.blank?

    message = Message.build do |m|
      m.token = SecureRandom.alphanumeric(6)
      m.link = content.link
      m.user = user
      m.body = substitute_variables(content.body, user, token: m.token)
      m.content = content
    end

    if save_user_and_message(user, message, content)
      Twilio::Client.new.send_message(message)
      Survey.trigger_for(user, message_count: user.programme_message_count)

      if user.finished_programme?
        user.update!(finished_content_at: Time.zone.now) if user.finished_content_at.nil?

        if user.programme_length.present?
          OffboardingMessageJob.set(wait_until: 1.week.from_now).perform_later(user)
        end
      end
    end
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
end
