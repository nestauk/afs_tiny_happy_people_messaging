# /Users/celia.collins/Code/afs_tiny_happy_people/test/factories/admin_notification.rb

FactoryBot.define do
  factory :admin_notification do
    sent_on { Date.current }
  end
end
