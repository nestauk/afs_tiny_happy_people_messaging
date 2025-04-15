require "test_helper"

class DemographicDataTest < ActiveSupport::TestCase
  test "should belong to a user" do
    demographic_data = DemographicData.new
    assert_respond_to demographic_data, :user
  end

  test "should be invalid without a user" do
    demographic_data = DemographicData.new
    assert_not demographic_data.valid?
    assert_includes demographic_data.errors[:user], "must exist"
  end
end
