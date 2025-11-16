FactoryBot.define do
  factory :medical_record do
    status { :pending }
    structured_data { {} }
    
    # Skip document validation by default for unit tests
    to_create { |instance| instance.save(validate: false) }

    trait :with_data do
      pet_name { 'Max' }
      species { 'Dog' }
      breed { 'Golden Retriever' }
      age { '5 years' }
      owner_name { 'John Doe' }
      diagnosis { 'Routine checkup' }
      treatment { 'Vaccination' }
      notes { 'Healthy pet' }
    end

    trait :completed do
      status { :completed }
      raw_text { 'Sample extracted text from document' }
      structured_data do
        {
          pet_name: 'Max',
          species: 'Dog',
          diagnosis: 'Routine checkup'
        }
      end
    end

    trait :processing do
      status { :processing }
    end

    trait :failed do
      status { :failed }
    end
  end
end
