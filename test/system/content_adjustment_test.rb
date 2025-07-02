require "application_system_test_case"

class ContentAdjustmentTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, contactable: true, child_birthday: 10.months.ago)
    create(:message, user: @user, status: "received")
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

    # User needs assessing, but is also not completed so shows in this tab as well
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

    # User needs assessing, but is also not completed so shows in this tab as well
    refute_selector "td", text: @user.full_name

    click_on "Incomplete"

    refute_selector "td", text: @user.full_name
  end
end
