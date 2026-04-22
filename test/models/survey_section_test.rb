require "test_helper"

class SurveySectionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @survey_section = create(:survey_section)
  end

  test "should be valid" do
    assert @survey_section.valid?
  end

  test "destroying survey destroys associated questions" do
    create(:question, survey_section: @survey_section)
    assert_difference "Question.count", -1 do
      @survey_section.destroy
    end
  end
end
