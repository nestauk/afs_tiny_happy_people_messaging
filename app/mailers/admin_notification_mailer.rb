class AdminNotificationMailer < ApplicationMailer
  def new_message_email
    mail(to: "info@cbeebies-text.uk", subject: "New message received")
  end
end
