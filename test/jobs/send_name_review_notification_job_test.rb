require "test_helper"

class SendNameReviewNotificationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "#perform sends an email to the admin inbox" do
    user = create(:user, needs_name_review: true)

    assert_emails 1 do
      SendNameReviewNotificationJob.new.perform(user)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["info@cbeebies-text.uk"], mail.to
    assert_equal "Name flagged for review", mail.subject
    assert_match "flagged for review", mail.body.encoded
  end
end
