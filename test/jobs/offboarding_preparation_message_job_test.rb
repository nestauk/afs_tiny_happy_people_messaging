require "test_helper"

class OffboardingPreparationMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends offboarding message in user's preferred language" do
    create(:group, language: "cy")
    user = create(:user, language: "cy")

    stub_successful_twilio_call("Rydych chi bron ar ddiwedd ein fideos! Mae ychydig mwy i ddod, a'r olaf ymhen mis. Oes gennych chi unrhyw adborth neu gwestiynau i ni y mis hwn?", user)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      OffboardingPreparationMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
  end

  test "#perform reports an error to Appsignal if message fails to save" do
    user = create(:user)

    Message.any_instance.stubs(:save).returns(false)
    Appsignal.expects(:report_error).once.with do |error|
      error.message == "Failed to send offboarding preparation message"
    end

    OffboardingPreparationMessageJob.new.perform(user)
  end
end
