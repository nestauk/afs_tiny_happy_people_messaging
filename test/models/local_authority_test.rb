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

  test "most_users_order scope" do
    create(:local_authority)
    create(:local_authority)

    create(:user, local_authority: @subject)
    create(:user, local_authority: @subject)
    create(:user, local_authority: @subject)
    create(:user, local_authority: @subject)

    assert_equal LocalAuthority.most_users_order.first, @subject
  end
end
