require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
    @group = create(:group)
  end

  test "creating new content" do
    sign_in
    visit group_path(@group)

    assert_text @group.name

    click_on "Add new message"

    fill_in "Body", with: "New content"
    fill_in "Link", with: "www.example.com"
    click_on "Create"

    assert_text "Content for message was successfully created"
    assert_text "New content"
  end

  test "updating a content" do
    create(:content, body: "Old Content", group: @group)

    sign_in
    visit group_path(@group)

    assert_text "Old Content"

    click_on "Edit", match: :first

    fill_in "Body", with: "Updated Content"
    click_on "Update"

    assert_text "Content updated!"
    assert_text "Updated Content"
  end

  private

  def sign_in
    visit new_admin_session_path
    fill_in "Email", with: @admin.email
    fill_in "Password", with: @admin.password
    click_on "Log in"
    assert_text "Signed in successfully."
  end
end
