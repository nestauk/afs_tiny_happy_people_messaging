FactoryBot.define do
  factory :group do
    name { 'Content for 18 month olds' }
    age_in_months { 18 }

    factory :group_with_experiment do
      experiment_name { 'shorter_msgs' }
    end
  end
end
