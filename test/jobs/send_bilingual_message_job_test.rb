require "test_helper"

class SendBilingualMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_name: "Harry")

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendBilingualMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_equal("Wales is a vibrant mix of many languages—and they all belong here! Speaking to Harry in your native language is a wonderful gift for their development. Learn more about bilingual households here:", Message.last.body)
    assert_not_nil user.sent_bilingual_text_at
  end

  test "#perform sends message for Welsh speakers" do
    create(:group, language: "cy")
    user = create(:user, language: "cy", child_name: "Harry")

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendBilingualMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_equal("Mae Cymru yn gymysgedd bywiog o lawer o ieithoedd—ac maen nhw i gyd yn perthyn yma! Mae siarad â Harry yn eich iaith frodorol yn rhodd werthfawr i’w datblygiad. Dysgwch fwy am aelwydydd dwyieithog yma:", Message.last.body)
    assert_not_nil user.sent_bilingual_text_at
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user)

    Message.any_instance.stubs(:save).returns(false)

    assert_no_enqueued_jobs do
      SendBilingualMessageJob.new.perform(user)
    end

    assert_equal 0, Message.count
  end
end
