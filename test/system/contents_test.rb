require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:admin)
    @group = create(:group)

    stub_request(:get, /www.example.com/).to_return(status: 200)
  end

  test "creating new content" do
    sign_in
    visit admin_group_path(@group)

    assert_text @group.name

    click_on "Add new message"

    fill_in "Body", with: "New content"
    fill_in "Link", with: "https://www.example.com"
    fill_in "Age in months", with: "18"
    click_on "Create"

    assert_text "Content for message was successfully created"
    assert_text "New content"
  end

  test "shows errors" do
    create(:content, body: "Old Content", group: @group)

    sign_in
    visit admin_group_path(@group)

    click_on "Add new message"

    click_on "Create"

    assert_field_has_errors("Body")
    assert_field_has_errors("Age in months")
  end

  test "updating content" do
    create(:content, body: "Old Content", group: @group)

    sign_in
    visit admin_group_path(@group)

    assert_text "Old Content"

    click_on "Edit", match: :first

    fill_in "Body", with: "Updated Content"
    click_on "Update"

    assert_text "Content updated!"
    assert_text "Updated Content"
  end

  test "archiving content" do
    content = create(:content, body: "Content to archive", group: @group)
    message = create(:message, user: create(:user), content:)

    sign_in
    visit admin_group_path(@group)

    assert_text "Content to archive"

    click_on "Archive", match: :first

    assert_text "Content archived"
    refute_text "Content to archive"

    assert_not_nil content.reload.archived_at
    assert_not_nil message.reload.content_id
  end
end
