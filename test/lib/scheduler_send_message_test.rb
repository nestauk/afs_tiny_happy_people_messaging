require "test_helper"

class SchedulerNotifyTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @content = create(:content, lower_age: @user.calculated_child_age)

    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["scheduler:send_message"].execute
  end

  test "message sent to user" do
    assert_equal @user.messages.last.body, @content.body
  end
end
