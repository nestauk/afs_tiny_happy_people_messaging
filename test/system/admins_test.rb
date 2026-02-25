require "application_system_test_case"

class AdminsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
  end

  test "creating an admin" do
    sign_in

    visit admin_admins_path
    assert_text "Admins"
    click_on "Create admin"

    fill_in "Email", with: "newadmin@example.com"
    click_button "Create admin"

    assert_text "Admin was successfully created"
    assert_text "newadmin@example.com"
  end

  test "can only edit yourself" do
    create(:admin, email: "admin2@example.com")

    sign_in(@admin)

    visit admin_admins_path

    within("tr", text: "admin2@example.com") do
      refute_text "Edit"
    end

    within("tr", text: @admin.email) do
      click_on "Edit"
    end

    fill_in "Email", with: "updatedadmin@example.com"
    click_on "Update"

    assert_text "Admin was successfully updated"
    assert_text "updatedadmin@example.com"
  end

  test "local authority users can't see users or content" do
    @admin = create(:admin, role: "local_authority", email: "local@authority.com")
    sign_in(@admin)

    assert_current_path admin_dashboard_path
    visit admin_users_path
    assert_current_path root_path

    visit admin_groups_path
    assert_current_path root_path
  end
end
