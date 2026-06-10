require "test_helper"

class AutoResponseMatchTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    create(:auto_response, trigger_phrase: "yes", response: "That's great to hear, thanks for letting us know!", update_user: "{\"asked_for_feedback\": false}", user_conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "no", response: "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences.", update_user: "{\"asked_for_feedback\": false}", user_conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    create(:auto_response, trigger_phrase: "end", update_user: "{\"contactable\": false}", response: "Please let us know why")
  end

  test "should match response to 'stop'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "stop", status: "received", user:)

    assert_no_changes Message.count do
      AutoResponseMatch.new(message: message).deliver
    end

    refute user.contactable
  end

  test "should match response to 'end'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "End", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    refute user.contactable
  end

  test "should match response to 'stop' on weekends" do
    travel_to Time.current.end_of_week
    user = create(:user, contactable: true)
    message = build(:message, body: "stop", status: "received", user:)

    assert_no_changes Message.count do
      AutoResponseMatch.new(message: message).deliver
    end

    refute user.contactable
  end

  test "should match response to 'start'" do
    user = create(:user, contactable: true)
    message = build(:message, body: "start", status: "received", user:)

    assert_no_changes Message.count do
      AutoResponseMatch.new(message: message).deliver
    end

    assert user.contactable
  end

  test "should match response to feedback 'yes'" do
    user = create(:user, asked_for_feedback: true)
    message = build(:message, body: "yes", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal user.asked_for_feedback, false
    assert_equal user.messages.last.body, "That's great to hear, thanks for letting us know!"
  end

  test "should match response to feedback 'no'" do
    user = create(:user, asked_for_feedback: true)
    message = build(:message, body: "no", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal user.asked_for_feedback, false
    assert_equal user.messages.last.body, "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if your child is not yet saying words, 2 if they are saying single words, 3 if they are saying whole sentences."
  end

  test "should not match response to feedback if user has not received feedback message" do
    user = create(:user, asked_for_feedback: false)
    message = build(:message, body: "no", status: "received", user:)

    assert_no_changes Message.count do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal user.asked_for_feedback, false
  end

  test "should not match response to unexpected messages on weekdays" do
    travel_to Time.current.beginning_of_week
    message = build(:message, body: "Hi there", status: "received")

    AutoResponseMatch.new(message: message).deliver

    assert_no_changes Message.count do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_no_changes message.user do
      AutoResponseMatch.new(message: message).deliver
    end
  end

  test "should match response to unexpected messages on weekends" do
    travel_to Time.current.end_of_week
    create(:group, language: "en")
    message = build(:message, body: "Hi there", status: "received")

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal message.user.messages.last.body, "The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can."
  end

  test "should ignore leading and trailing whitespace in the body" do
    user = create(:user, contactable: true)
    message = build(:message, body: "  stop  ", status: "received", user:)

    AutoResponseMatch.new(message: message).deliver

    refute user.contactable
  end

  test "should use the user's language for the out-of-hours response" do
    travel_to Time.current.end_of_week
    create(:group, language: "cy")
    user = create(:user, language: "cy")
    message = build(:message, body: "Hi there", status: "received", user:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal "Oriau gwaith y tîm yw 9am–6pm, dydd Llun i ddydd Gwener. Byddwn yn ymateb cyn gynted ag y gallwn.", user.messages.last.body
  end

  test "should fire only the first matching response when multiple share a trigger phrase" do
    create(:auto_response, trigger_phrase: "ping", response: "conditional reply", user_conditions: "{\"asked_for_feedback\": true}")
    create(:auto_response, trigger_phrase: "ping", response: "unconditional reply", user_conditions: "{}")
    user = create(:user, asked_for_feedback: false)
    message = build(:message, body: "ping", status: "received", user:)

    AutoResponseMatch.new(message: message).deliver

    assert_equal "unconditional reply", user.messages.last.body
  end

  test "should not change the user when update_user is empty" do
    create(:auto_response, trigger_phrase: "ping", response: "hi", update_user: "{}")
    user = create(:user, contactable: true, asked_for_feedback: true)
    message = build(:message, body: "ping", status: "received", user:)

    AutoResponseMatch.new(message: message).deliver
    user.reload

    assert user.contactable
    assert user.asked_for_feedback
  end

  test "doesn't fall over if updates aren't possible" do
    create(:auto_response, trigger_phrase: "restart", response: "You're all set to start receiving messages again!", update_user: "{\"contactable\": false}")
    user = create(:user)
    message = build(:message, body: "restart", status: "received", user:)
    user.phone_number = "1112"
    user.save(validate: false)
    refute user.valid?

    assert_enqueued_with(job: SendCustomMessageJob) do
      AutoResponseMatch.new(message: message).deliver
    end

    assert_equal user.messages.last.body, "You're all set to start receiving messages again!"
    refute user.contactable
  end
end
