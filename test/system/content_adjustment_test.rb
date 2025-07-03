require "application_system_test_case"

class ContentAdjustmentTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user, contactable: true, child_birthday: 10.months.ago)
    @admin = create(:admin)
  end

  test "admins can see users that need further help" do
    sign_in

    create(:content_adjustment, user: @user, needs_adjustment: true, direction: "not_sure")

    visit content_adjustments_path
    assert_selector "h1", text: "Adjustments"

    assert_selector "td", text: @user.full_name

    click_on "Incomplete"

    refute_selector "td", text: @user.full_name

    click_on "Completed"

    refute_selector "td", text: @user.full_name
  end

  test "admins can see users that are not finished with adjustments" do
    sign_in

    create(:content_adjustment, user: @user, needs_adjustment: true, direction: nil)

    visit content_adjustments_path
    assert_selector "h1", text: "Adjustments"
    click_on "Incomplete"

    assert_selector "td", text: @user.full_name

    click_on "Needs assessing"

    refute_selector "td", text: @user.full_name

    click_on "Completed"

    refute_selector "td", text: @user.full_name
  end

  test "admins can see users that have been automatically adjusted" do
    sign_in

    create(:content_adjustment, user: @user, needs_adjustment: true, direction: "up", adjusted_at: 1.day.ago)

    visit content_adjustments_path
    assert_selector "h1", text: "Adjustments"
    click_on "Completed"

    assert_selector "td", text: @user.full_name

    click_on "Needs assessing"

    refute_selector "td", text: @user.full_name

    click_on "Incomplete"

    refute_selector "td", text: @user.full_name
  end

  test "admins can update a user's content adjustment" do
    create(:content_adjustment, user: @user, needs_adjustment: true, direction: "not_sure")
    content = create(:content, age_in_months: 9, position: 1)
    sign_in

    visit content_adjustments_path
    assert_text @user.full_name
    click_on "Assess"

    assert_selector "h1", text: "#{@user.full_name}"

    click_on "Update content"

    assert_selector "h1", text: "#{@user.full_name}"

    fill_in "Content age", with: 9
    click_on "Update"

    assert_text "User's content has been updated."
    assert_equal @user.reload.last_content_id, content.id

    stub_successful_twilio_call("We've updated your content to match your requirements. Let us know if it still isn't appropriate by texting 'Adjust', we'll also check back in in a few weeks.", @user)

    perform_enqueued_jobs

    assert_equal Message.last.body, "We've updated your content to match your requirements. Let us know if it still isn't appropriate by texting 'Adjust', we'll also check back in in a few weeks."
  end
end
