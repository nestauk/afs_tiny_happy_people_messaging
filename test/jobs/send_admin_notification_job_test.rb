require "test_helper"

class SendAdminNotificationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "#perform sends an email to the admin inbox" do
    assert_emails 1 do
      SendAdminNotificationJob.new.perform
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["info@cbeebies-text.uk"], mail.to
    assert_equal "New message received", mail.subject
    assert_match "Log in to the dashboard", mail.body.encoded
  end
end
