require "test_helper"

class Admin::Dashboards::SignUpControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @local_authority = create(:local_authority)
    sign_in create(:admin)
  end

  test "fetch_sign_up_data by year" do
    travel_to Date.new(2025, 1, 1) do
      create(:user, local_authority: @local_authority)
      create(:user, local_authority: @local_authority, created_at: Date.new(2024, 12, 31))

      get admin_dashboards_sign_up_path, params: {q: @local_authority.name, timeframe: "year"}

      assert_response :success

      body = JSON.parse(response.body)

      expected_labels = 11.downto(0).map { |i| (Time.zone.today << i).strftime("%B %Y") }

      assert_equal "bar", body["type"]
      assert_equal expected_labels, body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by month" do
    travel_to Date.new(2024, 1, 30) do
      # 30 Jan
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: 1.year.ago.to_date)
      # 29 Jan
      create(:user, local_authority: @local_authority, created_at: Date.new(2024, 1, 29), child_birthday: 1.year.ago.to_date)
      # 30 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 30), child_birthday: 1.year.ago.to_date)

      get admin_dashboards_sign_up_path, params: {q: @local_authority.name, timeframe: "month"}

      assert_response :success

      body = JSON.parse(response.body)

      expected_labels = 30.downto(0).map { |i| (Time.zone.today - i).strftime("%d %B %Y") }

      assert_equal "bar", body["type"]
      assert_equal expected_labels, body["data"]["labels"]
      assert_equal [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by week when week starts below 7" do
    travel_to Date.new(2024, 1, 5) do
      # 5 Jan
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: 1.year.ago.to_date)
      # 30 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 30), child_birthday: 1.year.ago.to_date)

      get admin_dashboards_sign_up_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      expected_labels = 6.downto(0).map { |i| (Time.zone.today - i).strftime("%d %B %Y") }

      assert_equal "bar", body["type"]
      assert_equal expected_labels, body["data"]["labels"]
      assert_equal [0, 1, 0, 0, 0, 0, 2], body["data"]["datasets"].first["data"]
    end
  end

  test "fetch_sign_up_data by week when week starts above 7" do
    travel_to Date.new(2024, 1, 8) do
      # 7 Jan
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      create(:user, local_authority: @local_authority, child_birthday: 1.year.ago.to_date)
      # 31 Dec
      create(:user, local_authority: @local_authority, created_at: Date.new(2023, 12, 31), child_birthday: 1.year.ago.to_date)
      # 7 Jan 2022
      create(:user, local_authority: @local_authority, created_at: Date.new(2022, 1, 7), child_birthday: 1.year.ago.to_date)

      get admin_dashboards_sign_up_path, params: {q: @local_authority.name, timeframe: "week"}

      assert_response :success

      body = JSON.parse(response.body)

      expected_labels = 6.downto(0).map { |i| (Time.zone.today - i).strftime("%d %B %Y") }

      assert_equal "bar", body["type"]
      assert_equal expected_labels, body["data"]["labels"]
      assert_equal [0, 0, 0, 0, 0, 0, 2], body["data"]["datasets"].first["data"]
    end
  end
end
