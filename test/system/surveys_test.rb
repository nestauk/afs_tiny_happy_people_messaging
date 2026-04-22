require "application_system_test_case"

class SurveysTest < ApplicationSystemTestCase
  setup do
    @survey = create(:survey)
    @survey_section1 = create(:survey_section, survey: @survey, title_en: "Section 1", title_cy: "Adran 1", position: 1)
    @survey_section2 = create(:survey_section, survey: @survey, title_en: "Section 2", title_cy: "Adran 2", position: 2)
    @survey_section3 = create(:survey_section, survey: @survey, title_en: "Section 3", title_cy: "Adran 3", position: 3)
    @text_q = create(:question, survey_section: @survey_section1, text_en: "How are you feeling?", text_cy: "Sut ydych chi'n teimlo?", question_type: "text")
    @checkbox_q = create(:question, :check_boxes, survey_section: @survey_section2, text_en: "Which activities did you try?", text_cy: "Pa weithgareddau wnaethoch chi roi cynnig arnynt?", options_en: ["Option A", "Option B", "Option C"], options_cy: ["Opsiwn A", "Opsiwn B", "Opsiwn C"])
    @radio_q = create(:question, :radio_buttons, survey_section: @survey_section3, text_en: "Would you recommend this service?", text_cy: "A fyddech chi'n argymell y gwasanaeth hwn?", options_en: ["Yes", "No"], options_cy: ["Ydw", "Nac ydw"])
  end

  test "user can fill in a survey in English" do
    user = create(:user)
    token = user.generate_token_for(:survey_token)

    visit edit_survey_path(@survey, token:)

    assert_text @survey.title_en
    assert_text @survey_section1.title_en
    assert_text @survey_section2.title_en
    assert_text @survey_section3.title_en

    assert_text "How are you feeling?"
    assert_text "Which activities did you try?"
    assert_text "Would you recommend this service?"

    fill_in "How are you feeling?", with: "Really good"
    check "Option A"
    check "Option C"
    choose "Yes"

    click_button "Submit"

    assert_text "Thank you!"

    assert_equal "Really good", Answer.find_by(question: @text_q, user:).response
    assert_equal "Option A, Option C", Answer.find_by(question: @checkbox_q, user:).response
    assert_equal "Yes", Answer.find_by(question: @radio_q, user:).response
  end

  test "user can fill in a survey in Welsh" do
    create(:group, language: "cy")
    user = create(:user, language: "cy")
    token = user.generate_token_for(:survey_token)

    visit edit_survey_path(@survey, token:)

    assert_text @survey.title_cy
    assert_text @survey_section1.title_cy
    assert_text @survey_section2.title_cy
    assert_text @survey_section3.title_cy

    assert_text "Sut ydych chi'n teimlo?"
    assert_text "Pa weithgareddau wnaethoch chi roi cynnig arnynt?"
    assert_text "A fyddech chi'n argymell y gwasanaeth hwn?"

    fill_in "Sut ydych chi'n teimlo?", with: "Yn dda iawn"
    check "Opsiwn A"
    check "Opsiwn C"
    choose "Ydw"

    click_button "Submit"

    assert_text "Diolch!"

    assert_equal "Yn dda iawn", Answer.find_by(question: @text_q, user:).response
    assert_equal "Opsiwn A, Opsiwn C", Answer.find_by(question: @checkbox_q, user:).response
    assert_equal "Ydw", Answer.find_by(question: @radio_q, user:).response
  end

  test "user can't access survey without token" do
    create(:group)
    survey = create(:survey)
    visit edit_survey_path(survey)

    assert_current_path root_path(locale: "en")
    assert_text "Invalid survey link."
  end
end
