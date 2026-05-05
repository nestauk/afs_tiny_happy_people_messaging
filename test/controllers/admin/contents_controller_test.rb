require "test_helper"

class Admin::ContentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @group = create(:group)
    @content = create(:content, group: @group)
  end

  test "new returns success" do
    get new_admin_group_content_path(@group)
    assert_response :success
  end

  test "edit returns success" do
    get edit_admin_group_content_path(@group, @content)
    assert_response :success
  end

  test "create creates a content and redirects to the group" do
    CheckBbcLinksJob.expects(:perform_later)

    assert_difference "Content.count", 1 do
      post admin_group_contents_path(@group), params: {
        content: {body: "New content", link: "https://www.bbc.co.uk/new", age_in_months: 12, position: 99},
      }
    end
    assert_redirected_to admin_group_path(@group)
    assert_equal "Content for message was successfully created", flash[:notice]
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Content.count" do
      post admin_group_contents_path(@group), params: {
        content: {body: "", link: "not-a-url", age_in_months: nil, position: 99},
      }
    end
    assert_response :unprocessable_entity
  end

  test "update updates content and redirects to the group" do
    patch admin_group_content_path(@group, @content), params: {
      content: {body: "Updated body"},
    }
    assert_redirected_to admin_group_path(@group)
    assert_equal "Updated body", @content.reload.body
    assert_equal "Content updated!", flash[:notice]
  end

  test "update re-renders edit with invalid params" do
    patch admin_group_content_path(@group, @content), params: {
      content: {body: ""},
    }
    assert_response :unprocessable_entity
    assert_not_equal "", @content.reload.body
  end

  test "update_position updates the content position and returns no_content" do
    second = create(:content, group: @group)
    create(:content, group: @group)
    assert_equal 2, second.reload.position

    patch admin_update_position_path(second), params: {position: 1}
    assert_response :no_content
    assert_equal 1, second.reload.position
  end

  test "archive sets archived_at and redirects to the group" do
    assert_nil @content.archived_at
    travel_to Time.current.beginning_of_minute do
      patch archive_admin_group_content_path(@group, @content)
      assert_redirected_to admin_group_path(@group)
      assert_equal Time.current, @content.reload.archived_at
    end
    assert_equal "Content archived", flash[:notice]
  end

  test "local authority admins are redirected away from new" do
    sign_out @admin
    sign_in create(:admin, role: "local_authority", email: "la@example.com")
    get new_admin_group_content_path(@group)
    assert_response :redirect
  end

  test "local authority admins cannot create content" do
    sign_out @admin
    sign_in create(:admin, role: "local_authority", email: "la@example.com")

    assert_no_difference "Content.count" do
      post admin_group_contents_path(@group), params: {
        content: {body: "Blocked", link: "https://www.bbc.co.uk/x", age_in_months: 12, position: 99},
      }
    end
    assert_response :redirect
  end

  test "unauthenticated requests are redirected to sign in" do
    sign_out @admin
    get new_admin_group_content_path(@group)
    assert_redirected_to new_admin_session_path
  end
end
