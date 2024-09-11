# /Users/celia.collins/Code/afs_tiny_happy_people/test/factories/message.rb

FactoryBot.define do
  factory :message do
    body { "Here's a parenting tip" }

    user
  end
end
