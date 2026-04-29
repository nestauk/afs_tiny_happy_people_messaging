require "test_helper"

class SendWaitlistMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call("Hi! Thanks for joining the waitlist for our programme of weekly texts with fun activities for your child's development. We'll be in touch when it's time to get started. In the meantime, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", user)

    SendWaitlistMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match("Hi! Thanks for joining the waitlist for our programme of weekly texts with fun activities for your child's development. We'll be in touch when it's time to get started. In the meantime, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", Message.last.body)
  end

  test "#perform sends message in user's preferred language" do
    create(:group, language: "cy")
    user = create(:user, child_birthday: 18.months.ago, language: "cy")

    stub_successful_twilio_call("Helo! Diolch am ymuno â rhestr aros ein negeseuon wythnosol llawn syniadau i gefnogi datblygiad dy blentyn. Byddwn mewn cysylltiad pan fydd hi’n bryd dechrau. Yn y cyfamser, arbeda’r rhif hwn fel 'CBeebies Parenting'.", user)

    SendWaitlistMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match("Helo! Diolch am ymuno â rhestr aros ein negeseuon wythnosol llawn syniadau i gefnogi datblygiad dy blentyn. Byddwn mewn cysylltiad pan fydd hi’n bryd dechrau. Yn y cyfamser, arbeda’r rhif hwn fel 'CBeebies Parenting'.", Message.last.body)
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    SendWaitlistMessageJob.new.perform(user)

    assert_equal 0, Message.count
  end
end
