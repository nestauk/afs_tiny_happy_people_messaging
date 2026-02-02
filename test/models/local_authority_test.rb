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

  test "count_users_by_created_at" do
    create(:user, local_authority: @subject, created_at: Time.zone.local(2021, 1, 1))
    create(:user, local_authority: @subject, created_at: Time.zone.local(2021, 2, 21))
    create(:user, local_authority: @subject, created_at: Time.zone.local(2021, 5, 24))

    assert_equal @subject.count_users_by_created_at("%B %Y"), {"January 2021" => 1, "February 2021" => 1, "May 2021" => 1}
  end

  test "percentage_messages_clicked_by_created_at" do
    user = create(:user, local_authority: @subject)
    content = create(:content)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 1), clicked_at: Time.zone.local(2021, 1, 2), content:)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 10), content:)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 15)) # Should not be counted as doesn't have content
    create(:message, user:, created_at: Time.zone.local(2021, 2, 1), clicked_at: Time.zone.local(2021, 1, 2), content:)

    assert_equal @subject.percentage_messages_clicked_by_created_at("%B %Y"), {"January 2021" => 50.0, "February 2021" => 100.0}
  end

  test "count_messages_by_created_at" do
    user = create(:user, local_authority: @subject)
    content = create(:content)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 1), content:)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 10), content:)
    create(:message, user:, created_at: Time.zone.local(2021, 1, 15)) # Should not be counted as doesn't have content
    create(:message, user:, created_at: Time.zone.local(2021, 2, 1), content:)

    assert_equal @subject.count_messages_by_created_at("%B %Y"), {"January 2021" => 2, "February 2021" => 1}
  end
end
