require "test_helper"

class MessageVariableSubstitutionTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  class TestJob
    include MessageVariableSubstitution
    include Rails.application.routes.url_helpers

    public :substitute_variables
  end

  setup do
    @job = TestJob.new
  end

  test "substitutes parent name" do
    user = build(:user, first_name: "Ali")
    assert_equal "Hi Ali!", @job.substitute_variables("Hi {{parent_name}}!", user)
  end

  test "substitutes parent name and removes whitespace when no parent name is present" do
    user = build(:user, first_name: "")
    assert_equal "Hi!", @job.substitute_variables("Hi {{parent_name}}!", user)
  end

  test "substitutes child name" do
    user = build(:user, child_name: "Sam")
    assert_equal "Hi Sam!", @job.substitute_variables("Hi {{child_name}}!", user)
  end

  test "uses your_child fallback when child name is blank" do
    user = build(:user, child_name: nil)
    assert_equal "Message for your child.", @job.substitute_variables("Message for {{child_name}}.", user)
  end

  test "does not leave a dangling space before punctuation when parent name is blank" do
    user = build(:user, first_name: nil)
    assert_equal "Hi!", @job.substitute_variables("Hi {{parent_name}}!", user)
  end

  test "does not leave a dangling space before comma when parent name is blank" do
    user = build(:user, first_name: nil)
    assert_equal "Hi, welcome.", @job.substitute_variables("Hi {{parent_name}}, welcome.", user)
  end

  test "collapses double space when parent name is blank mid-sentence" do
    user = build(:user, first_name: nil)
    assert_equal "Hello there.", @job.substitute_variables("Hello {{parent_name}} there.", user)
  end

  test "substitutes link when token is provided" do
    user = build(:user)
    result = @job.substitute_variables("Click {{link}}", user, token: "abc123")
    assert_includes result, track_link_url("abc123")
  end

  test "substitutes multiple variables" do
    user = build(:user, first_name: "Ali", child_name: "Sam")
    result = @job.substitute_variables("Hi {{parent_name}}, this is for {{child_name}}.", user)
    assert_equal "Hi Ali, this is for Sam.", result
  end
end
