require "test_helper"

class AnonymiseUsersJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform anonymises users who were created more than 3 years ago" do
    old_user = create(:user, created_at: 4.years.ago)
    recent_user = create(:user, created_at: 2.years.ago)

    AnonymiseUsersJob.new.perform

    assert old_user.reload.anonymised_at.present?
    assert old_user.first_name.nil?
    assert old_user.child_name.nil?
    assert_equal "anonymised", old_user.phone_number
    assert_equal "anonymised", old_user.postcode

    assert recent_user.reload.anonymised_at.nil?
  end

  test "#perform raises and reports errors" do
    create(:user, created_at: 4.years.ago)
    User.any_instance.stubs(:update!).raises(StandardError.new("Something went wrong"))

    Appsignal.expects(:report_error).once.with do |error|
      error.message == "Something went wrong"
    end

    AnonymiseUsersJob.new.perform
  end
end
