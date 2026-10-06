class SendNameReviewNotificationJob < ApplicationJob
  queue_as :background

  def perform(user)
    AdminNotificationMailer.name_needs_review_email(user).deliver_now
  end
end
