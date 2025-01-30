require "test_helper"

class ResponseMatcherServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    create(:auto_response, trigger_phrase: "pause", response: "Thanks, you've paused for 4 weeks.", update_user: '{"contactable": false, "restart_at": "4.weeks.from_now.noon"}')
    create(:auto_response, trigger_phrase: "yes", response: "That's great to hear, thanks for letting us know!", update_user: "{\"asked_for_feedback\": false}", conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "no", response: "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences.", update_user: "{\"asked_for_feedback\": false}", conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    create(:auto_response, trigger_phrase: "start", update_user: "{\"contactable\": true}")
  end
  test "should match response to 'pause'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "pause", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    refute user.contactable
    assert_not_nil user.restart_at
  end

  test "should match response to 'stop'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "stop", status: "received", user:)

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    refute user.contactable
  end

  test "should match response to 'stop' on weekends" do
    travel_to Time.current.end_of_week
    user = create(:user, contactable: true)
    message = build(:message, body: "stop", status: "received", user:)

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    refute user.contactable
  end

  test "should match response to 'start'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "start", status: "received", user:)

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    assert user.contactable
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
    assert_equal user.messages.last.body, "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences."
  end

  test "should not match response to feedback if user has not received feedback message" do
    user = create(:user, asked_for_feedback: false)
    message = build(:message, body: "no", status: "received", user:)

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.asked_for_feedback, false
  end

  test "should not match response to unexpected messages on weekdays" do
    travel_to Time.current.beginning_of_week
    message = build(:message, body: "Hi there", status: "received")

    ResponseMatcherService.new(message).match_response

    assert_no_changes Message.count do
      ResponseMatcherService.new(message).match_response
    end

    assert_no_changes message.user do
      ResponseMatcherService.new(message).match_response
    end
  end

  test "should match response to unexpected messages on weekends" do
    travel_to Time.current.end_of_week
    message = build(:message, body: "Hi there", status: "received")

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal message.user.messages.last.body, "The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can."
  end

  test "doesn't fall over if updates aren't possible" do
    create(:auto_response, trigger_phrase: "restart", response: "You're all set to start receiving messages again!", update_user: "{\"contactable\": false}")
    user = create(:user)
    message = build(:message, body: "restart", status: "received", user:)
    user.child_birthday = 1.month.ago
    user.save(validate: false)
    refute user.valid?

    assert_enqueued_with(job: SendCustomMessageJob) do
      ResponseMatcherService.new(message).match_response
    end

    assert_equal user.messages.last.body, "You're all set to start receiving messages again!"
    refute user.contactable
  end
end
