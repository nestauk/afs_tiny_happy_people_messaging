require "test_helper"

class Admin::GroupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @group = create(:group)
  end

  test "new returns success" do
    get new_admin_group_path
    assert_response :success
  end

  test "edit returns success" do
    get edit_admin_group_path(@group)
    assert_response :success
  end

  test "show returns success" do
    get admin_group_path(@group)
    assert_response :success
  end

  test "create creates a group and redirects to the group" do
    assert_difference "Group.count", 1 do
      post admin_groups_path, params: {
        group: {name: "New Group", language: "en"},
      }
    end
    assert_redirected_to admin_groups_path
    assert_equal "Content group successfully created", flash[:notice]
    assert_equal "New Group", Group.last.name
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Group.count" do
      post admin_groups_path, params: {
        group: {name: ""},
      }
    end
    assert_response :unprocessable_entity
  end

  test "update updates group and redirects" do
    patch admin_group_path(@group), params: {group: {name: "Updated Group"}}
    assert_redirected_to admin_groups_path
    assert_equal "Updated Group", @group.reload.name
  end

  test "destroy deletes group and redirects" do
    assert_difference "Group.count", -1 do
      delete admin_group_path(@group)
    end
    assert_redirected_to admin_groups_path
  end
end
