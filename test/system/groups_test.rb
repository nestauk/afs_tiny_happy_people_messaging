require "application_system_test_case"

class GroupsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
  end

  test "creating new group" do
    sign_in
    visit groups_path

    click_on "Create content group"

    fill_in "Name", with: "Default content"
    fill_in "Age in months", with: "17"
    click_on "Create"

    assert_text "Content group successfully created"
    assert_text "Default content"
  end

  test "shows errors" do
    sign_in
    visit groups_path

    click_on "Create content group"

    click_on "Create"

    assert_field_has_errors("Name")
    assert_field_has_errors("Age in months")
  end

  test "updating a group" do
    create(:group, name: "Old group name")

    sign_in
    visit groups_path

    assert_text "Old group name"

    click_on "Edit", match: :first

    fill_in "Name", with: "New group name"
    click_on "Update"

    assert_text "Content group updated"
    assert_text "New group name"
  end
end