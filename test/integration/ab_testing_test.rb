require 'test_helper'

class AbTestingTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    create(:group) do |group|
      group.contents.create(attributes_for(:content))
    end
    create(:group_with_experiment) do |group|
      group.contents.create(attributes_for(:content))
    end
  end

  test 'user#next_content returns control variant' do
    experiment = FieldTest::Experiment.find(:shorter_msgs)
    experiment.variant(@user, variant: 'control')

    assert_nil @user.next_content.group.experiment_name
  end

  test 'user#next_content returns treatment variant' do
    experiment = FieldTest::Experiment.find(:shorter_msgs)
    experiment.variant(@user, variant: 'treatment')

    assert_equal 'shorter_msgs', @user.next_content.group.experiment_name
  end
end
