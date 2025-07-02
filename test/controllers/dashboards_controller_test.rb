require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @local_authority = create(:local_authority)
    sign_in create(:admin)
  end

  test "fetch_sign_up_data by year" do
    travel_to Date.new(2025, 1, 1) do
      puts Date.current
      create(:user, local_authority: @local_authority)
      create(:user, local_authority: @local_authority, created_at: Date.new(2024, 12, 31))

      get dashboards_fetch_sign_up_data_path, params: {q: @local_authority.name, timeframe: "year"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "bar", body["type"]
      assert_equal [
        "February 2024",
        "March 2024",
        "April 2024",
        "May 2024",
        "June 2024",
        "July 2024",
        "August 2024",
        "September 2024",
        "October 2024",
        "November 2024",
        "December 2024",
        "January 2025"
      ], body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by month" do
    travel_to Date.new(2024, 1, 30) do
      puts Date.current
      # 30 Jan
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 4, 1))
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 4, 1))
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: Date.new(2023, 4, 1))
      # 29 Jan
      create(:user, local_authority: @local_authority, created_at: Date.new(2024, 1, 29), child_birthday: Date.new(2023, 4, 1))
      # 30 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 30), child_birthday: Date.new(2023, 4, 1))

      get dashboards_fetch_sign_up_data_path, params: {q: @local_authority.name, timeframe: "month"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "bar", body["type"]
      assert_equal [
        "31 December 2023",
        "01 January 2024",
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024",
        "06 January 2024",
        "07 January 2024",
        "08 January 2024",
        "09 January 2024",
        "10 January 2024",
        "11 January 2024",
        "12 January 2024",
        "13 January 2024",
        "14 January 2024",
        "15 January 2024",
        "16 January 2024",
        "17 January 2024",
        "18 January 2024",
        "19 January 2024",
        "20 January 2024",
        "21 January 2024",
        "22 January 2024",
        "23 January 2024",
        "24 January 2024",
        "25 January 2024",
        "26 January 2024",
        "27 January 2024",
        "28 January 2024",
        "29 January 2024",
        "30 January 2024"
      ], body["data"]["labels"]
      assert_equal [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by week when week starts below 7" do
    travel_to Date.new(2024, 1, 5) do
      puts Date.current
      # 5 Jan
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: Date.new(2023, 4, 1))
      # 30 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 30), child_birthday: Date.new(2023, 4, 1))

      get dashboards_fetch_sign_up_data_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "bar", body["type"]
      assert_equal [
        "30 December 2023",
        "31 December 2023",
        "01 January 2024",
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024"
      ], body["data"]["labels"]
      assert_equal [0, 1, 0, 0, 0, 0, 2], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by week when week starts above 7" do
    travel_to Date.new(2024, 1, 8) do
      puts Date.current
      # 7 Jan
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: Date.new(2023, 4, 1))
      # 7 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 7), child_birthday: Date.new(2023, 4, 1))

      get dashboards_fetch_sign_up_data_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "bar", body["type"]
      assert_equal [
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024",
        "06 January 2024",
        "07 January 2024",
        "08 January 2024"
      ], body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 2], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_click_through_data by year" do
    travel_to Date.new(2025, 1, 1) do
      puts Date.current
      content = create(:content)
      user = create(:user, local_authority: @local_authority)
      create(:message, content:, user:, created_at: Date.new(2024, 12, 31), clicked_at: Date.new(2025, 1, 1))
      create(:message, content:, user:, created_at: Date.new(2024, 12, 31))
      create(:message, content:, user:, created_at: Date.new(2025, 1, 31), clicked_at: Date.new(2025, 1, 1))

      get dashboards_fetch_click_through_data_path, params: {q: @local_authority.name, timeframe: "year"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "line", body["type"]
      assert_equal [
        "February 2024",
        "March 2024",
        "April 2024",
        "May 2024",
        "June 2024",
        "July 2024",
        "August 2024",
        "September 2024",
        "October 2024",
        "November 2024",
        "December 2024",
        "January 2025"
      ], body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50.0, 100.0], body["data"]["datasets"].first["data"]
      assert_equal [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1], body["data"]["datasets"].second["data"]
    end
  end

  test "fetch_click_through_data by month" do
    travel_to Date.new(2024, 1, 30) do
      puts Date.current
      content = create(:content)
      user = create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      create(:message, content:, user:, created_at: Date.new(2023, 12, 31), clicked_at: Date.new(2025, 1, 1))
      create(:message, content:, user:, created_at: Date.new(2023, 12, 31))
      create(:message, content:, user:, created_at: Date.new(2024, 1, 30), clicked_at: Date.new(2025, 1, 1))

      get dashboards_fetch_click_through_data_path, params: {q: @local_authority.name, timeframe: "month"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "line", body["type"]
      assert_equal [
        "31 December 2023",
        "01 January 2024",
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024",
        "06 January 2024",
        "07 January 2024",
        "08 January 2024",
        "09 January 2024",
        "10 January 2024",
        "11 January 2024",
        "12 January 2024",
        "13 January 2024",
        "14 January 2024",
        "15 January 2024",
        "16 January 2024",
        "17 January 2024",
        "18 January 2024",
        "19 January 2024",
        "20 January 2024",
        "21 January 2024",
        "22 January 2024",
        "23 January 2024",
        "24 January 2024",
        "25 January 2024",
        "26 January 2024",
        "27 January 2024",
        "28 January 2024",
        "29 January 2024",
        "30 January 2024"
      ], body["data"]["labels"]
      assert_equal [50.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100.0], body["data"]["datasets"].first["data"]
      assert_equal [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], body["data"]["datasets"].second["data"]
    end
  end

  test "fetch_click_through_data by week when week starts below 7" do
    travel_to Date.new(2024, 1, 5) do
      puts Date.current
      content = create(:content)
      user = create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      create(:message, content:, user:, created_at: Date.new(2024, 1, 5), clicked_at: Date.new(2025, 1, 1))
      create(:message, content:, user:, created_at: Date.new(2024, 1, 5))
      create(:message, content:, user:, created_at: Date.new(2023, 12, 30), clicked_at: Date.new(2025, 1, 1))

      get dashboards_fetch_click_through_data_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "line", body["type"]
      assert_equal [
        "30 December 2023",
        "31 December 2023",
        "01 January 2024",
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024"
      ], body["data"]["labels"]
      assert_equal [100.0, 0, 0, 0, 0, 0, 50.0], body["data"]["datasets"].first["data"]
      assert_equal [1, 0, 0, 0, 0, 0, 2], body["data"]["datasets"].second["data"]
    end
  end

  test "fetch_click_through_data by week when week starts above 7" do
    travel_to Date.new(2024, 1, 8) do
      puts Date.current
      content = create(:content)
      user = create(:user, local_authority: @local_authority, child_birthday: Date.new(2023, 5, 1))
      create(:message, content:, user:, created_at: Date.new(2024, 1, 8), clicked_at: Date.new(2025, 1, 1))
      create(:message, content:, user:, created_at: Date.new(2024, 1, 8))
      create(:message, content:, user:, created_at: Date.new(2023, 12, 30), clicked_at: Date.new(2025, 1, 1))

      get dashboards_fetch_click_through_data_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal "line", body["type"]
      assert_equal [
        "02 January 2024",
        "03 January 2024",
        "04 January 2024",
        "05 January 2024",
        "06 January 2024",
        "07 January 2024",
        "08 January 2024"
      ], body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 50.0], body["data"]["datasets"].first["data"]
      assert_equal [0, 0, 0, 0, 0, 0, 2], body["data"]["datasets"].second["data"]
    end
  end

  test "cannot fetch data without signing in" do
    sign_out :admin

    get dashboards_fetch_sign_up_data_path, params: {q: @local_authority.name, timeframe: "year"}

    assert_response :redirect
    assert_redirected_to new_admin_session_path
  end
end
