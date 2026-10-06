class AdminNotificationMailer < ApplicationMailer
  def new_message_email
    mail(to: "info@cbeebies-text.uk", subject: "New message received")
  end

  def name_needs_review_email(user)
    @user = user
    mail(to: "info@cbeebies-text.uk", subject: "Name flagged for review")
  end
end
