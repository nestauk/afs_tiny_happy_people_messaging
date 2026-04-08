require "test_helper"

class RestartMessagesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform updates user and sends message" do
    user = create(:user, contactable: false)

    User.any_instance.stubs(:generate_profile_token).returns("123")

    stub_successful_twilio_call("Welcome to CBeebies Parenting! Your child is now old enough to start receiving activities. Fill in the registration form to get started #{edit_user_url(user, token: "123")}.", user)

    RestartMessagesJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal true, user.contactable
  end

  test "#perform sends restart message in user's preferred language" do
    create(:group, language: "cy")
    user = create(:user, contactable: false, language: "cy")
    User.any_instance.stubs(:generate_profile_token).returns("123")

    stub_successful_twilio_call("Croeso i CBeebies Parenting! Mae eich plentyn bellach yn ddigon hen i ddechrau derbyn gweithgareddau. Llenwch y ffurflen gofrestru i ddechrau #{edit_user_url(user, token: "123")}.", user)

    RestartMessagesJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal true, user.contactable
  end
end
