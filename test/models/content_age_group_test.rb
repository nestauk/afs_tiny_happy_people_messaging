require "test_helper"

class ContentAgeGroupTest < ActiveSupport::TestCase
  def setup
    @subject = create(:content_age_group)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test("description required") { assert_present(:description) }
  test("min_months required") { assert_present(:min_months) }
  test("max_months required") { assert_present(:max_months) }

  test ".return_two_groups returns next two oldest groups" do
    group2 = create(:content_age_group, min_months: 8, max_months: 10)
    group3 = create(:content_age_group, min_months: 11, max_months: 13)
    create(:content_age_group, min_months: 14, max_months: 16)

    assert_equal [group2, group3], ContentAgeGroup.return_two_groups(">", 6)
  end

  test ".return_two_groups returns one older group if only one available" do
    create(:content_age_group, min_months: 8, max_months: 10)
    create(:content_age_group, min_months: 11, max_months: 13)
    group = create(:content_age_group, min_months: 14, max_months: 16)

    assert_equal [group], ContentAgeGroup.return_two_groups(">", 12)
  end

  test ".return_two_groups returns next two younger groups" do
    group = create(:content_age_group, min_months: 8, max_months: 10)
    create(:content_age_group, min_months: 11, max_months: 13)
    create(:content_age_group, min_months: 14, max_months: 16)

    assert_equal [@subject, group], ContentAgeGroup.return_two_groups("<", 11)
  end

  test ".return_two_groups returns one younger group if only available" do
    create(:content_age_group, min_months: 8, max_months: 10)
    create(:content_age_group, min_months: 11, max_months: 13)
    create(:content_age_group, min_months: 14, max_months: 16)

    assert_equal [@subject], ContentAgeGroup.return_two_groups("<", 10)
  end
end
