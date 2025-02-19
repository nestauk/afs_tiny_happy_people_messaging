require "application_system_test_case"

class DiaryEntriesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
  end

  test "user can fill in a diary entry" do
    visit new_user_diary_entry_path(user_uuid: @user.uuid)

    fill_in_diary_entry_form

    click_button "Finish"

    assert_text "Thank you for filling out your diary entry this week!"

    assert_equal 1, @user.diary_entries.count
    diary_entry = @user.diary_entries.last

    assert_equal ["Monday", "Wednesday"], diary_entry.days
    assert_equal ["Mornings"], diary_entry.timings
    assert_equal 30, diary_entry.total_time
    assert_equal true, diary_entry.did_previous_week_activity
    refute diary_entry.first_week
    assert_equal "I did laundry with her", diary_entry.activities_from_previous_weeks
    assert_equal ["Interesting?"], diary_entry.feedback
    assert_equal "It was interesting", diary_entry.feedback_reason
    assert_equal "I was busy", diary_entry.reason_for_not_doing_activity
    assert_equal "I had fun", diary_entry.enjoyed_most
    assert_equal "I was too busy", diary_entry.enjoyed_least
    assert_equal "Fewer reminders", diary_entry.changes_to_make
    refute_nil diary_entry.completed_at
  end

  test "I can complete the form without filling in any the fields" do
    visit new_user_diary_entry_path(user_uuid: @user.uuid)

    assert_text "Hello! Welcome to another week of our diary study"

    click_button "Next"

    assert_text "Reflecting on this week's text"

    click_button "Next"

    assert_text "Reflecting on previous week's text"

    click_button "Next"

    assert_text "Feedback on this week's text"

    click_button "Finish"

    assert_text "Thank you for filling out your diary entry this week!"

    assert_equal 1, @user.diary_entries.count
    diary_entry = @user.diary_entries.last
    refute_nil diary_entry.completed_at
  end

  test "The form saves my answers if I go back" do
    visit new_user_diary_entry_path(user_uuid: @user.uuid)

    fill_in_diary_entry_form

    click_button "Back"

    assert_text "Reflecting on previous week's text"

    click_button "Back"

    assert_text "Reflecting on this week's text"

    assert_checked_field "Monday"
    assert_checked_field "Wednesday"
    assert_checked_field "Mornings"
    assert_field "When you got the chance to engage with the tips or activities you received in the text this week, how long did you typically spend doing each activity?", with: "30"

    click_button "Next"

    assert_text "Reflecting on previous week's text"
    assert_checked_field "Yes"
    assert_field "[IF YES TO PREVIOUS QUESTION] What tips or activities from previous weeks did you engage with this week?", with: "I did laundry with her"

    click_button "Next"

    assert_text "Feedback on this week's text"

    assert_checked_field "Interesting?"
    assert_field "Tell us more about why you selected the choices above, and what you thought about the text message and activity you received.", with: "It was interesting"
    assert_field "If you didn’t do the activities in the text or watch the video, what was the reason?", with: "I was busy"
    assert_field "What have you enjoyed most about the programme this week?", with: "I had fun"
    assert_field "What have you enjoyed least about the programme this week?", with: "I was too busy"
    assert_field "What would you change about the programme this week, if anything?", with: "Fewer reminders"
  end

  test "The form correctly saves if it was my first week" do
    visit new_user_diary_entry_path(user_uuid: @user.uuid)

    assert_text "Hello! Welcome to another week of our diary study"

    click_button "Next"

    assert_text "Reflecting on this week's text"

    click_button "Next"

    assert_text "Reflecting on previous week's text"

    choose "This is my first week of texts"

    click_button "Next"

    assert_text "Feedback on this week's text"

    click_button "Finish"

    assert_text "Thank you for filling out your diary entry this week!"

    assert @user.diary_entries.last.first_week
    assert_nil @user.diary_entries.last.did_previous_week_activity
  end

  private

  def fill_in_diary_entry_form
    assert_text "Hello! Welcome to another week of our diary study"

    click_button "Next"

    assert_text "Reflecting on this week's text"

    check "Monday"
    check "Wednesday"

    check "Mornings"

    fill_in "When you got the chance to engage with the tips or activities you received in the text this week, how long did you typically spend doing each activity?", with: "30"

    click_button "Next"

    assert_text "Reflecting on previous week's text"

    choose "Yes"

    fill_in "If you said yes to the previous question, what tips or activities from previous weeks did you engage with this week?", with: "I did laundry with her"

    click_button "Next"

    assert_text "Feedback on this week's text"

    check "Interesting?"

    fill_in "Tell us more about why you selected the choices above, and what you thought about the text message and activity you received.", with: "It was interesting"
    fill_in "If you didn’t do the activities in the text or watch the video, what was the reason?", with: "I was busy"
    fill_in "What have you enjoyed most about the programme this week?", with: "I had fun"
    fill_in "What have you enjoyed least about the programme this week?", with: "I was too busy"
    fill_in "What would you change about the programme this week, if anything?", with: "Fewer reminders"
  end
end
