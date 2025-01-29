require "test_helper"

class AutoResponseTest < ActiveSupport::TestCase
  def setup
    @subject = build(:auto_response)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("trigger_phrase required") { assert_present(:trigger_phrase) }

  test "should validate conditions JSON" do
    @subject.conditions = "{blah: 'blah'}"

    assert_raises(JSON::ParserError) { @subject.save }
  end

  test "should validate update_user JSON" do
    @subject.update_user = "{blah: 'blah'}"

    assert_raises(JSON::ParserError) { @subject.save }
  end

  test "should validate conditions fields" do
    @subject.conditions = '{"blah": "blah"}'
    @subject.valid?
    assert_error(:conditions, "invalid field 'blah' - not found in User model")
  end

  test "should validate update_user fields" do
    @subject.update_user = '{"blah": "blah"}'
    @subject.valid?
    assert_error(:update_user, "invalid field 'blah' - not found in User model")
  end
end
