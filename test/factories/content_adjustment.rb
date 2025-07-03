FactoryBot.define do
  factory :content_adjustment do
    needs_adjustment { nil }
    direction { nil }
    adjusted_at { nil }

    user
  end
end
