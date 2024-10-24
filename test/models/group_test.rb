require "test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @subject = build(:group)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("name required") { assert_present(:name) }
  test("age_in_months required") { assert_present(:age_in_months) }

  test "#weekly_content" do
    weekly_content = create(:content, group: @subject)
    create(:content, group: @subject, welcome_message: true)

    assert_equal [weekly_content], @subject.weekly_content
  end

  test "#welcome_message" do
    welcome_message = create(:content, group: @subject, welcome_message: true)
    create(:content, group: @subject, welcome_message: false)

    assert_equal welcome_message, @subject.welcome_message
  end
end
