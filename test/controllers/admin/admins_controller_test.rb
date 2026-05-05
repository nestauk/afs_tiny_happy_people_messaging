require "test_helper"

class Admin::AdminsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin, email: "admin@example.com")
    sign_in @admin
  end

  test "index lists all admins" do
    other = create(:admin, email: "other@example.com")
    get admin_admins_path
    assert_response :success
    assert_see @admin.email
    assert_see other.email
  end

  test "new returns success" do
    get new_admin_admin_path
    assert_response :success
  end

  test "edit returns success" do
    other = create(:admin, email: "other@example.com")
    get edit_admin_admin_path(other)
    assert_response :success
  end

  test "create creates an admin and redirects to index" do
    assert_difference "Admin.count", 1 do
      post admin_admins_path, params: {admin: {email: "newadmin@example.com"}}
    end
    assert_redirected_to admin_admins_path
    assert_equal "Admin was successfully created.", flash[:notice]
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Admin.count" do
      post admin_admins_path, params: {admin: {email: ""}}
    end
    assert_response :unprocessable_entity
  end

  test "create rejects duplicate email" do
    assert_no_difference "Admin.count" do
      post admin_admins_path, params: {admin: {email: @admin.email}}
    end
    assert_response :unprocessable_entity
  end

  test "update updates admin email and redirects to index" do
    other = create(:admin, email: "other@example.com")
    patch admin_admin_path(other), params: {admin: {email: "renamed@example.com"}}
    assert_redirected_to admin_admins_path
    assert_equal "renamed@example.com", other.reload.email
  end

  test "update re-renders edit with invalid params" do
    other = create(:admin, email: "other@example.com")
    patch admin_admin_path(other), params: {admin: {email: ""}}
    assert_response :unprocessable_entity
    assert_equal "other@example.com", other.reload.email
  end

  test "update on the current admin keeps the session signed in" do
    patch admin_admin_path(@admin), params: {admin: {email: "renamed@example.com"}}
    assert_redirected_to admin_admins_path

    # a follow-up authenticated request should still succeed
    get admin_admins_path
    assert_response :success
  end

  test "local authority admins are redirected away from index" do
    sign_out @admin
    sign_in create(:admin, email: "la@example.com", role: "local_authority")
    get admin_admins_path
    assert_response :redirect
  end

  test "local authority admins are redirected away from create" do
    sign_out @admin
    sign_in create(:admin, email: "la@example.com", role: "local_authority")
    assert_no_difference "Admin.count" do
      post admin_admins_path, params: {admin: {email: "blocked@example.com"}}
    end
    assert_response :redirect
  end

  test "unauthenticated requests are redirected to sign in" do
    sign_out @admin
    get admin_admins_path
    assert_redirected_to new_admin_session_path
  end
end
