require "test_helper"

class AdminTest < ActiveSupport::TestCase
  require "test_helper"

  test "should not save admin without email" do
    admin = build(:admin, email: nil)
    assert_not admin.save, "Saved the admin without an email"
  end

  test "should not save admin with duplicate email" do
    create(:admin, email: "test@example.com")
    admin2 = build(:admin, email: "test@example.com")
    assert_not admin2.save, "Saved the admin with a duplicate email"
  end

  test "should have a default role" do
    admin = build(:admin, email: "test@example.com")
    admin.save
    assert_includes ["admin", "local_authority"], admin.role, "Admin role is not set to a valid default"
  end
end
