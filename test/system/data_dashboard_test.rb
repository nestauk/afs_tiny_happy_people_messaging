require "application_system_test_case"

class DataDashboardTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)

    hackney = create(:local_authority, name: "Hackney")
    york = create(:local_authority, name: "York")

    user1 = create(:user, local_authority: hackney)
    user2 = create(:user, local_authority: york)
    create(:user, local_authority: york, created_at: 1.year.ago)

    content = create(:content)
    create(:message, user: user1, clicked_at: Time.now, content:)
    create(:message, user: user2, created_at: 1.year.ago, content:)

    AllLasDashboard.refresh
    LaSpecificDashboard.refresh
  end

  test "shows all local authority data" do
    sign_in

    visit dashboard_path

    assert_selector "div.border-purple-500" do
      assert_text "Total number of sign ups"
      assert_text "3"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Sign ups this month"
      assert_text "2"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Sign ups this year"
      assert_text "2"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Average click through rate"
      assert_text "50%"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Average click through rates this month"
      assert_text "100%"
    end
  end

  test "shows local authority specific data" do
    sign_in

    visit dashboard_path

    select "York"

    assert_selector "div.border-purple-500" do
      assert_text "Total number of sign ups"
      assert_text "2"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Sign ups this month"
      assert_text "1"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Sign ups this year"
      assert_text "1"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Average click through rate"
      assert_text "100%"
    end

    assert_selector "div.border-purple-500" do
      assert_text "Average click through rates this month"
      assert_text "100%"
    end
  end
end
