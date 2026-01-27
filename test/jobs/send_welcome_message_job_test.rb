require "test_helper"

class SendWelcomeMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call("Hi Ali, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal("Hi Ali, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'Tiny Happy People' so you can easily see when it's us texting you?", Message.last.body)
  end

  test "#perform sends message for Welsh speakers" do
    user = create(:user, child_birthday: 18.months.ago, language: "cy")

    stub_successful_twilio_call("Helo Ali, croeso i’n rhaglen o negeseuon wythnosol gyda gweithgareddau hwyliog ar gyfer datblygiad eich plentyn. Llongyfarchiadau ar ddechrau’r daith ryfeddol hon gyda’ch un bach! I ddechrau, beth am gadw’r rhif hwn fel ‘Tiny Happy People’ fel eich bod yn gwybod mai ni sy’n anfon negeseuon atoch?", user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal("Helo Ali, croeso i’n rhaglen o negeseuon wythnosol gyda gweithgareddau hwyliog ar gyfer datblygiad eich plentyn. Llongyfarchiadau ar ddechrau’r daith ryfeddol hon gyda’ch un bach! I ddechrau, beth am gadw’r rhif hwn fel ‘Tiny Happy People’ fel eich bod yn gwybod mai ni sy’n anfon negeseuon atoch?", Message.last.body)
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 0, Message.count
  end

  test "#perform triggers surveys with message_count 0 after sending" do
    user = create(:user, child_birthday: 18.months.ago)
    create(:survey, send_after_message_count: 0)

    Twilio::Client.any_instance.stubs(:send_message)

    assert_enqueued_jobs 1, only: SendSurveyJob do
      SendWelcomeMessageJob.new.perform(user)
    end
  end

  test "#perform does not trigger surveys if message fails to save" do
    user = create(:user, child_birthday: 18.months.ago)
    create(:survey, send_after_message_count: 0)

    Message.any_instance.stubs(:save).returns(false)

    assert_no_enqueued_jobs only: SendSurveyJob do
      SendWelcomeMessageJob.new.perform(user)
    end
  end
end
