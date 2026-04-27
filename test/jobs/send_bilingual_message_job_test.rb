require "test_helper"

class SendBilingualMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_name: "Harry")

    Message.any_instance.stubs(:generate_token).returns("ABC")

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendBilingualMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_equal("Wales celebrates all languages! Using your home language(s) is a gift for Harry's development. Learn more: http://localhost:3000/m/ABC", Message.last.body)
    assert_not_nil user.sent_bilingual_text_at
  end

  test "#perform sends message for Welsh speakers" do
    create(:group, language: "cy")
    user = create(:user, language: "cy", child_name: "Harry")

    Message.any_instance.stubs(:generate_token).returns("ABC")

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendBilingualMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_equal("Mae Cymru'n dathlu pob iaith! Mae siarad eich mamiaith yn anrheg i ddatblygiad Harry. Dysgwch fwy: http://localhost:3000/m/ABC", Message.last.body)
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
