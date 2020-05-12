FactoryBot.define do
  factory :archive do
    trait :pending do
      status { 'pending' }
    end

    trait :generated do
      status { 'generated' }
    end
  end
end
