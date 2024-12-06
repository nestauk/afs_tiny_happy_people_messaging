require "test_helper"

class GroupTest < ActiveSupport::TestCase
  def setup
    @subject = build(:group)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("name required") { assert_present(:name) }
end
