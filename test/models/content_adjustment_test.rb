require "test_helper"

class ContentAdjustmentTest < ActiveSupport::TestCase
  def setup
    @subject = create(:content_adjustment)
  end

  test "should be valid" do
    assert @subject.valid?
  end

  test "complete scope returns only completed adjustments" do
    old_completed_adjustment = create(:content_adjustment, adjusted_at: Time.now)
    new_completed_adjustment = create(:content_adjustment, adjusted_at: Time.now, user: old_completed_adjustment.user)
    incomplete_adjustment = create(:content_adjustment, adjusted_at: nil)

    assert_includes ContentAdjustment.complete, old_completed_adjustment
    assert_includes ContentAdjustment.complete, new_completed_adjustment
    refute_includes ContentAdjustment.complete, incomplete_adjustment
  end

  test "incomplete scope returns only incomplete adjustments" do
    incomplete_adjustment1 = create(:content_adjustment, adjusted_at: nil, needs_adjustment: true, direction: "up")
    incomplete_adjustment2 = create(:content_adjustment, adjusted_at: nil, needs_adjustment: true, direction: nil)
    completed_adjustment1 = create(:content_adjustment, adjusted_at: Time.now)
    completed_adjustment2 = create(:content_adjustment, direction: "not_sure")

    assert_includes ContentAdjustment.incomplete, incomplete_adjustment1
    assert_includes ContentAdjustment.incomplete, incomplete_adjustment2
    refute_includes ContentAdjustment.incomplete, completed_adjustment1
    refute_includes ContentAdjustment.incomplete, completed_adjustment2
  end
end
