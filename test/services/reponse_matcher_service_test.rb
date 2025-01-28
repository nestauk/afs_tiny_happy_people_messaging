require "test_helper"

class ResponseMatcherServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    create(:auto_response, trigger_phrase: "pause", response: "Thanks, you've paused for 4 weeks.", update_user: '{"contactable": false, "restart_at": "4.weeks.from_now.noon"}')
    create(:auto_response, trigger_phrase: "yes", response: "That's great to hear, thanks for letting us know!", update_user: "{\"asked_for_feedback\": false}", conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "no", response: "We can adjust the activities we send. Respond 1 if they are too simple or 2 if they are too advanced.", update_user: "{\"asked_for_feedback\": false}", conditions: "{\"asked_for_feedback\": true}")
  end
  test "should match response to 'pause'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "pause", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.contactable, false
    assert_not_nil user.restart_at
  end

  test "should match response to feedback 'yes'" do
    user = create(:user, asked_for_feedback: true)
    message = build(:message, body: "yes", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.asked_for_feedback, false
    assert_equal user.messages.last.body, "That's great to hear, thanks for letting us know!"
  end

  test "should match response to feedback 'no'" do
    user = create(:user, asked_for_feedback: true)
    message = build(:message, body: "no", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.asked_for_feedback, false
    assert_equal user.messages.last.body, "We can adjust the activities we send. Respond 1 if they are too simple or 2 if they are too advanced."
  end

  test "should not match response to feedback if user has not received feedback message" do
    user = create(:user, asked_for_feedback: false)
    message = build(:message, body: "no", status: "received", user:)

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.asked_for_feedback, false
  end

  test "should not match response to unexpected message" do
    message = build(:message, body: "Hi there", status: "received")

    ResponseMatcherService.new(message).match_response

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end
  end
end
