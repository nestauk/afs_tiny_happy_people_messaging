require "test_helper"

class Admin::AutoResponsesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @auto_response = create(:auto_response)
  end

  test "#index shows all auto responses" do
    get admin_auto_responses_path
    assert_response :success
  end

  test "edit returns success" do
    get edit_admin_auto_response_path(@auto_response)
    assert_response :success
  end

  test "update updates auto response and redirects" do
    patch admin_auto_response_path(@auto_response), params: {auto_response: {response: "New response"}}
    assert_redirected_to admin_auto_responses_path
    assert_equal "New response", @auto_response.reload.response
  end

  test "update re-renders edit with invalid params" do
    AutoResponse.any_instance.stubs(:update).returns(false)

    assert_no_difference "AutoResponse.count" do
      patch admin_auto_response_path(@auto_response), params: {
        auto_response: {response: ""},
      }
    end
    assert_response :unprocessable_content
  end
end
