require "test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @subject = build(:group)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("name required") { assert_present(:name) }

  test "#weekly_content" do
    weekly_content = create(:content, group: @subject)
    create(:content, group: @subject, welcome_message: true)

    assert_equal [weekly_content], @subject.weekly_content
  end
end
