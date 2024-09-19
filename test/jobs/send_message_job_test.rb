require 'test_helper'

class SendMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#perform sends messages with default content if no body present' do
    user = create(:user)
    content = create(:content, lower_age: user.child_age_in_months_today)

    stub_successful_twilio_call(content.body, user)

    SendMessageJob.new.perform(user:)

    assert_equal 1, Message.count
    assert_equal content.body, Message.last.body
  end

  test '#perform does not send message if no appropriate content available' do
    SendMessageJob.new.perform(user: create(:user))
    assert_equal 0, Message.count
  end

  test '#perform sends messages with content if body present' do
    user = create(:user)

    stub_successful_twilio_call('Custom Body', user)

    SendMessageJob.perform_now(user:, body: 'Custom Body')

    assert_equal 1, Message.count
    assert_equal 'Custom Body', Message.last.body
  end
end
