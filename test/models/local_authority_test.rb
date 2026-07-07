require "test_helper"

class LocalAuthorityTest < ActiveSupport::TestCase
  setup { @subject = create(:local_authority) }

  test "should be valid" do
    assert @subject.valid?
  end

  test "has_many users" do
    create(:user, local_authority: @subject)
    assert_equal(1, @subject.users.size)
  end
  test("name required") { assert_present(:name) }
end
