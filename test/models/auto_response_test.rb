require "test_helper"

class AutoResponseTest < ActiveSupport::TestCase
  def setup
    @subject = build(:auto_response)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("trigger_phrase required") { assert_present(:trigger_phrase) }

  test "should validate user conditions JSON" do
    @subject.user_conditions = '{blah: "blah"}'
    @subject.valid?

    assert_error(:user_conditions, "must be a valid JSON object")
  end

  test "should validate update_user JSON" do
    @subject.update_user = '{blah: "blah"}'
    @subject.valid?

    assert_error(:update_user, "must be a valid JSON object")
  end

  test "should validate user conditions fields" do
    @subject.user_conditions = '{"blah": "blah"}'
    @subject.valid?
    assert_error(:user_conditions, "invalid field 'blah' - not found in User model")
  end

  test "should validate update_user fields" do
    @subject.update_user = '{"blah": "blah"}'
    @subject.valid?
    assert_error(:update_user, "invalid field 'blah' - not found in User model")
  end
end
