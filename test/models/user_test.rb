# FILEPATH: /Users/celia.collins/Code/afs_tiny_happy_people/test/models/user_test.rb

require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { @subject = create(:user) }

  test "should be valid" do
    assert @subject.valid?
  end

  test "has_many messages" do
    create(:message, user: @subject)
    assert_equal(1, @subject.messages.size)
  end

  test "has_many interests" do
    create(:interest, user: @subject)
    assert_equal(1, @subject.interests.size)
  end

  test("phone_number required") { assert_present(:phone_number) }
  test("first_name required") { assert_present(:first_name) }
  test("last_name required") { assert_present(:last_name) }
  test("child_age required") { assert_present(:child_age) }

  test "should have a contactable scope" do
    create(:user, contactable: false)

    assert_equal User.contactable.size, 1
    assert_equal User.contactable, [@subject]
  end

  test "child_age_in_months_today method" do
    user = create(:user, child_age: 5)

    assert_equal user.child_age_in_months_today, 5
  end
end
