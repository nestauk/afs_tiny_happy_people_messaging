class SendAdminNotificationJob < ApplicationJob
  queue_as :background

  def perform
    AdminNotificationMailer.new_message_email.deliver_now
  end
end
