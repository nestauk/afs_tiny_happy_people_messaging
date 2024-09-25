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

  test "shows errors" do
    create(:content, body: "Old Content", group: @group)

    sign_in
    visit group_path(@group)

    click_on "Add new message"

    click_on "Create"

    assert_field_has_errors("Body")
    assert_field_has_errors("Link")
  end

  test "updating content" do
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

  test "deleting content" do
    content = create(:content, body: "Content to delete", group: @group)
    message = create(:message, user: create(:user), content: content)

    sign_in
    visit group_path(@group)

    assert_text "Content to delete"

    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Content deleted"
    refute_text "Content to delete"

    assert_nil message.reload.content
  end
end
