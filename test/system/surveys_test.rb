require "application_system_test_case"

class SurveysTest < ApplicationSystemTestCase
  test "user can fill in a survey" do
    survey = create(:survey)
    text_q = create(:question, survey:, text: "How are you feeling?", question_type: "text")
    checkbox_q = create(:question, :check_boxes, survey:, text: "Which activities did you try?", options: ["Option A", "Option B", "Option C"])
    radio_q = create(:question, :radio_buttons, survey:, text: "Would you recommend this service?", options: ["Yes", "No"])

    user = create(:user)
    token = user.generate_token_for(:survey_token)

    visit edit_survey_path(survey, token:)

    assert_text "How are you feeling?"
    assert_text "Which activities did you try?"
    assert_text "Would you recommend this service?"

    fill_in "How are you feeling?", with: "Really good"
    check "Option A"
    check "Option C"
    choose "Yes"

    click_button "Submit"

    assert_text "Thank you for completing the survey!"

    assert_equal "Really good", Answer.find_by(question: text_q, user:).response
    assert_equal "Option A, Option C", Answer.find_by(question: checkbox_q, user:).response
    assert_equal "Yes", Answer.find_by(question: radio_q, user:).response
  end

  test "user can't access survey without token" do
    create(:group)
    survey = create(:survey)
    visit edit_survey_path(survey)

    assert_current_path root_path
    assert_text "Invalid survey link."
  end
end
