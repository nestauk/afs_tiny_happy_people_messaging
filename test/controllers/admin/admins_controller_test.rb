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

  test "create sets the chosen role when the current admin is a super admin" do
    @admin.update!(role: "super_admin")

    post admin_admins_path, params: {admin: {email: "newadmin@example.com", role: "super_admin"}}

    assert_equal "super_admin", Admin.find_by(email: "newadmin@example.com").role
  end

  test "create ignores the role param when the current admin is not a super admin" do
    post admin_admins_path, params: {admin: {email: "newadmin@example.com", role: "super_admin"}}

    assert_equal "admin", Admin.find_by(email: "newadmin@example.com").role
  end

  test "update ignores the role param when the current admin is not a super admin" do
    other = create(:admin, email: "other@example.com", role: "admin")

    patch admin_admin_path(other), params: {admin: {role: "super_admin"}}

    assert_equal "admin", other.reload.role
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

  test "unauthenticated requests are redirected to sign in" do
    sign_out @admin
    get admin_admins_path
    assert_redirected_to new_admin_session_path
  end

  test "an admin with the admin role can access admin-gated pages" do
    @admin.update!(role: "admin")
    get admin_admins_path
    assert_response :success
  end

  test "an admin with the super_admin role can access admin-gated pages" do
    @admin.update!(role: "super_admin")
    get admin_admins_path
    assert_response :success
  end

  test "destroy deletes the admin and redirects to index" do
    other = create(:admin, email: "other@example.com")

    assert_difference "Admin.count", -1 do
      delete admin_admin_path(other)
    end

    assert_redirected_to admin_admins_path
    assert_equal "Admin was successfully deleted.", flash[:notice]
    assert_not Admin.exists?(other.id)
  end
end
