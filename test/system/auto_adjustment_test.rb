require "application_system_test_case"

class AutoAdjustmentTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  setup do
    stub_request(:any, /www.example.com/).to_return(status: 200)
    content = create(:content, age_in_months: 10, group: create(:group))
    @user = create(:user, contactable: true, child_birthday: 10.months.ago, last_content_id: content.id)
    create_all_auto_responses
    create(:content_age_group, min_months: 3, max_months: 6, description: "Tiny Koala")
    create(:content_age_group, min_months: 7, max_months: 9, description: "Tiny Bumblebee")
    create(:content_age_group, min_months: 10, max_months: 12, description: "Tiny Elephant")
    create(:content_age_group, min_months: 13, max_months: 18, description: "Tiny Penguin")
    create(:content_age_group, min_months: 19, max_months: 27, description: "Tiny Dolphin")

    group = create(:group)
    @lower_content = create(:content, age_in_months: 3, position: 1, group: group)
    @upper_content = create(:content, age_in_months: 13, position: 1, group: group)
  end

  test "User can say they don't need any adjustments" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "Yes", status: "received")

    stub_successful_twilio_call("That's great to hear, thanks for letting us know!", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    refute @user.asked_for_feedback
    refute @user.latest_adjustment.needs_adjustment
  end

  test "User can say they need an adjustment up" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment

    Message.create(user: @user, body: "1", status: "received")

    stub_successful_twilio_call("Thanks for the feedback. Are you one of these groups?\n1. Tiny Penguin\n2. Tiny Dolphin\n3. I'm not sure", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment.needs_adjustment
    assert_equal "up", @user.latest_adjustment.direction

    Message.create(user: @user, body: "1", status: "received")

    stub_successful_twilio_call("Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.", @user)

    perform_enqueued_jobs
    assert_equal Message.last.body, "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right."

    refute @user.latest_adjustment.needs_adjustment
    refute_nil @user.latest_adjustment.adjusted_at
    assert_equal @upper_content.id, @user.last_content_id
  end

  test "User can say they need an adjustment down" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment

    Message.create(user: @user, body: "2", status: "received")

    stub_successful_twilio_call("Thanks for the feedback. Are you one of these groups?\n1. Tiny Koala\n2. Tiny Bumblebee\n3. I'm not sure", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment.needs_adjustment
    assert_equal "down", @user.latest_adjustment.direction

    Message.create(user: @user, body: "1", status: "received")

    stub_successful_twilio_call("Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.", @user)

    perform_enqueued_jobs
    assert_equal Message.last.body, "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right."

    refute @user.latest_adjustment.needs_adjustment
    refute_nil @user.latest_adjustment.adjusted_at
    assert_equal @lower_content.id, @user.last_content_id
  end

  test "User can say they need an adjustment up and they have a young child" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)
    content = create(:content, age_in_months: 4, group: create(:group))
    @user.update(child_birthday: 4.months.ago, last_content_id: content.id)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment
    assert_equal @user.latest_adjustment.number_down_options, 0
    assert_equal @user.latest_adjustment.number_up_options, 2

    Message.create(user: @user, body: "1", status: "received")

    stub_successful_twilio_call("Thanks for the feedback. Are you one of these groups?\n1. Tiny Bumblebee\n2. Tiny Elephant\n3. I'm not sure", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment.needs_adjustment
    assert_equal "up", @user.latest_adjustment.direction
  end

  test "User can give more context if they're not sure if they want easier or harder content" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    Message.create(user: @user, body: "My child is not saying anything and they're 2", status: "received")

    stub_successful_twilio_call("Thanks, a member of the team will be in touch to discuss your child's needs.", @user)

    perform_enqueued_jobs

    assert_equal Message.last.body, "Thanks, a member of the team will be in touch to discuss your child's needs."
    assert_equal @user.latest_adjustment.direction, "not_sure"

    # Check we don't get in a loop of sending the same message
    Message.create(user: @user, body: "Thank you", status: "received")

    perform_enqueued_jobs

    assert_equal Message.last.body, "Thank you"
  end

  test "User can give more context if they're not sure which group they belong to" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment

    Message.create(user: @user, body: "2", status: "received")

    stub_successful_twilio_call("Thanks for the feedback. Are you one of these groups?\n1. Tiny Koala\n2. Tiny Bumblebee\n3. I'm not sure", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment.needs_adjustment
    assert_equal "down", @user.latest_adjustment.direction
    assert_equal 2, @user.latest_adjustment.number_down_options
    content_id = @user.last_content_id

    Message.create(user: @user, body: "3", status: "received")

    stub_successful_twilio_call("Thanks, a member of the team will be in touch to discuss your child's needs.", @user)

    perform_enqueued_jobs
    assert_equal Message.last.body, "Thanks, a member of the team will be in touch to discuss your child's needs."

    assert @user.latest_adjustment.needs_adjustment
    assert_equal @user.latest_adjustment.direction, "not_sure"
    assert_equal content_id, @user.last_content_id
  end

  test "User can give more context if they're not sure which group they belong to and there are two options" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)
    content = create(:content, age_in_months: 7, group: create(:group))
    @user.update(child_birthday: 7.months.ago, last_content_id: content.id)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment

    Message.create(user: @user, body: "2", status: "received")

    stub_successful_twilio_call("Thanks for the feedback. Are you one of these groups?\n1. Tiny Koala\n2. I'm not sure", @user)

    perform_enqueued_jobs

    assert @user.latest_adjustment.needs_adjustment
    assert_equal "down", @user.latest_adjustment.direction
    assert_equal 1, @user.latest_adjustment.number_down_options
    content_id = @user.last_content_id

    Message.create(user: @user, body: "2", status: "received")

    stub_successful_twilio_call("Thanks, a member of the team will be in touch to discuss your child's needs.", @user)

    perform_enqueued_jobs
    assert_equal Message.last.body, "Thanks, a member of the team will be in touch to discuss your child's needs."

    assert @user.latest_adjustment.needs_adjustment
    assert_equal @user.latest_adjustment.direction, "not_sure"
    assert_equal content_id, @user.last_content_id
  end

  test "User gets appropriate message if there aren't any options to adjust" do
    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond 'Yes' or 'No' to let us know.", @user)
    @user.update(child_birthday: 6.months.ago, last_content_id: nil)

    SendFeedbackMessageJob.new.perform(@user)

    perform_enqueued_jobs

    assert @user.latest_adjustment
    assert @user.asked_for_feedback

    Message.create(user: @user, body: "no", status: "received")

    stub_successful_twilio_call("We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment
    assert_equal 0, @user.latest_adjustment.number_down_options

    Message.create(user: @user, body: "2", status: "received")

    stub_successful_twilio_call("Thanks, a member of the team will be in touch to discuss your child's needs.", @user)

    perform_enqueued_jobs

    refute @user.asked_for_feedback
    assert @user.latest_adjustment.needs_adjustment
    assert_equal @user.latest_adjustment.direction, "not_sure"
  end
end
