# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :recommendation do
    user_id 1
    exercise_id 1
    result_id 1
    type ""
    recommended_user_id 1
    times_accepted 1
  end
end
