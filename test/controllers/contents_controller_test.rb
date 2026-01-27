require "test_helper"

class ContentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @group = create(:group)
  end

  test "admins can access" do
    admin = create(:admin)
    sign_in admin
    get admin_group_path(@group)
    assert_response :success
  end

  test "local authority admins can't access" do
    admin = create(:admin, role: "local_authority")
    sign_in admin
    get admin_group_path(@group)
    assert_response :redirect
  end
end
