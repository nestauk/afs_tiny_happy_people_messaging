require "application_system_test_case"

class GroupsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
  end

  test "creating new group" do
    sign_in
    visit admin_groups_path

    click_on "Create content group"

    fill_in "Name", with: "Default content"
    click_on "Create"

    assert_text "Content group successfully created"
    assert_text "Default content"
  end

  test "can choose another language" do
    sign_in
    visit admin_groups_path

    click_on "Create content group"

    fill_in "Name", with: "Default content"
    select "Welsh", from: "Language"
    click_on "Create"

    assert_text "Content group successfully created"
    assert_text "Default content"
    assert_equal "cy", Group.last.language
  end

  test "shows errors" do
    sign_in
    visit admin_groups_path

    click_on "Create content group"

    click_on "Create"

    assert_field_has_errors("Name")
  end

  test "updating a group" do
    create(:group, name: "Old group name")

    sign_in
    visit admin_groups_path

    assert_text "Old group name"

    click_on "Edit", match: :first

    fill_in "Name", with: "New group name"
    click_on "Update"

    assert_text "Content group updated"
    assert_text "New group name"
  end

  test "deleting a group" do
    group = create(:group, name: "Group to delete")
    create(:message, user: create(:user), content: group.contents.first)

    sign_in
    visit admin_groups_path

    assert_text "Group to delete"

    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Content group deleted"
    refute_text "Group to delete"
  end
end
