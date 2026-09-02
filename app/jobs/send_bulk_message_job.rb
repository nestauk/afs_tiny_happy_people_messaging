class SendBulkMessageJob < ApplicationJob
  queue_as :real_time

  def perform(message_type, time = nil)
    case message_type
    when "weekly_message"
      Appsignal::CheckIn.cron("send_#{time}_job") do
        enqueue_in_batches(users_for(time).map { |user| SendMessageJob.new(user) })
      end
    when "bilingual_text"
      enqueue_in_batches(User.wales.contactable.received_six_messages_without_bilingual_text.map { |user| SendBilingualMessageJob.new(user) })
    when "feedback"
      enqueue_in_batches(User.contactable.received_two_or_eighteen_messages.map { |user| SendFeedbackMessageJob.new(user) })
    when "nudge"
      enqueue_in_batches(User.contactable.not_nudged.not_clicked_last_x_messages(3).map { |user| NudgeUsersJob.new(user) })
    when "restart"
      enqueue_in_batches(User.due_for_restart.map { |user| RestartMessagesJob.new(user) })
    when "survey_reminder"
      survey = Survey.find_by(title_en: "Pre-programme survey")
      if survey
        enqueue_in_batches(User.contactable.needs_survey_reminder(survey.id).map { |user| SendSurveyReminderJob.new(user, survey) })
      end
    when "offboarding"
      enqueue_in_batches(User.wales.contactable.with_four_messages_left.uniq.map { |user| OffboardingPreparationMessageJob.new(user) })
    end
  end

  private

  def users_for(time)
    base = User.not_finished.contactable.with_preference_for_day(Time.zone.today.wday)
    case time
    when "morning" then base.wants_morning_message
    when "afternoon" then base.wants_afternoon_message
    when "evening" then base.wants_evening_message
    when "no_preference" then base.no_hour_preference_message
    end
  end

  # Stagger enqueued jobs so message-sending jobs execute in batches spread a
  # second apart, keeping SMS sends under our AWS Pinpoint account's rate limit.
  def enqueue_in_batches(jobs)
    return if jobs.empty?

    jobs.each_slice(Sms::Client::BATCH_SIZE).with_index do |batch, index|
      next if index.zero? # first batch sends immediately, same as before batching existed

      batch.each { |job| job.set(wait: index.seconds) }
    end

    ActiveJob.perform_all_later(jobs)
  end
end
