FactoryBot.define do
  factory :answer do
    response { "Some response" }
    user
    question
  end
end
