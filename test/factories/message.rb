# /Users/celia.collins/Code/afs_tiny_happy_people/test/factories/message.rb

FactoryBot.define do
  factory :message do
    body { "Here's a parenting tip" }

    user

    factory :sent_message do
      link { content.link }
      status { "sent" }
      sent_at { Time.zone.now }
      sequence(:message_sid) { |n| "message-sid-#{n}" }

      content
    end
  end
end
