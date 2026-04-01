require "test_helper"

class Admin::SurveysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @survey = create(:survey)
  end

  test "index lists all surveys" do
    get admin_surveys_path
    assert_response :success
    assert_see @survey.title_en
  end

  test "create creates a survey and redirects" do
    assert_difference "Survey.count", 1 do
      post admin_surveys_path, params: {survey: {title_en: "New Survey", title_cy: "Arolwg Newydd"}}
    end
    assert_redirected_to admin_surveys_path
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Survey.count" do
      post admin_surveys_path, params: {survey: {title_en: "", title_cy: ""}}
    end
    assert_response :unprocessable_entity
  end

  test "update updates survey and redirects" do
    patch admin_survey_path(@survey), params: {survey: {title_en: "Updated Title"}}
    assert_redirected_to admin_survey_path(@survey)
    assert_equal "Updated Title", @survey.reload.title_en
  end

  test "destroy deletes survey and redirects" do
    assert_difference "Survey.count", -1 do
      delete admin_survey_path(@survey)
    end
    assert_redirected_to admin_surveys_path
  end
end
