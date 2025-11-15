require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GroqStructuringService, type: :service do
  let(:raw_text) do
    <<~TEXT
      Veterinary Medical Record
      
      Patient Name: Max
      Species: Dog
      Breed: Golden Retriever
      Age: 3 years
      Owner Name: John Smith
      Date: 2025-11-15
      
      Diagnosis: Annual checkup
      Treatment: Vaccinations updated
      Veterinarian: Dr. Sarah Johnson
    TEXT
  end

  let(:groq_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => {
              "pet_name" => "Max",
              "species" => "Dog",
              "breed" => "Golden Retriever",
              "age" => "3 years",
              "owner_name" => "John Smith",
              "diagnosis" => "Annual checkup",
              "treatment" => "Vaccinations updated",
              "veterinarian" => "Dr. Sarah Johnson",
              "date" => "2025-11-15"
            }.to_json
          }
        }
      ]
    }
  end

  before do
    ENV['GROQ_API_KEY'] = 'test_api_key'
    ENV['GROQ_API_URL'] = 'https://api.groq.com/openai/v1/chat/completions'
  end

  after do
    ENV.delete('GROQ_API_KEY')
    ENV.delete('GROQ_API_URL')
  end

  describe '#structure' do
    context 'when Groq API returns valid data' do
      before do
        stub_request(:post, "https://api.groq.com/openai/v1/chat/completions")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer test_api_key'
            }
          )
          .to_return(
            status: 200,
            body: groq_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns structured data with all fields' do
        service = described_class.new(raw_text)
        result = service.structure

        expect(result).to be_a(Hash)
        expect(result[:pet_name]).to eq('Max')
        expect(result[:species]).to eq('Dog')
        expect(result[:breed]).to eq('Golden Retriever')
        expect(result[:age]).to eq('3 years')
        expect(result[:owner_name]).to eq('John Smith')
        expect(result[:diagnosis]).to eq('Annual checkup')
        expect(result[:treatment]).to eq('Vaccinations updated')
        expect(result[:veterinarian]).to eq('Dr. Sarah Johnson')
        expect(result[:date]).to eq('2025-11-15')
      end
    end

    context 'when Groq API returns nested JSON' do
      let(:nested_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => {
                  "patient_info" => {
                    "pet_name" => "Max",
                    "species" => "Dog",
                    "breed" => "Golden Retriever"
                  },
                  "owner_info" => {
                    "owner_name" => "John Smith"
                  }
                }.to_json
              }
            }
          ]
        }
      end

      before do
        stub_request(:post, "https://api.groq.com/openai/v1/chat/completions")
          .to_return(
            status: 200,
            body: nested_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'flattens nested structures' do
        service = described_class.new(raw_text)
        result = service.structure

        expect(result[:pet_name]).to eq('Max')
        expect(result[:species]).to eq('Dog')
        expect(result[:breed]).to eq('Golden Retriever')
        expect(result[:owner_name]).to eq('John Smith')
      end
    end

    context 'when raw text is blank' do
      it 'returns empty hash' do
        service = described_class.new('')
        result = service.structure

        expect(result).to eq({})
      end
    end

    context 'when Groq API returns an error' do
      before do
        stub_request(:post, "https://api.groq.com/openai/v1/chat/completions")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns empty hash and logs error' do
        service = described_class.new(raw_text)
        result = service.structure

        expect(result).to eq({})
      end
    end

    context 'when Groq API returns invalid JSON' do
      before do
        stub_request(:post, "https://api.groq.com/openai/v1/chat/completions")
          .to_return(
            status: 200,
            body: { "choices" => [{ "message" => { "content" => "not a valid json" } }] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns empty hash' do
        service = described_class.new(raw_text)
        result = service.structure

        expect(result).to eq({})
      end
    end
  end

  describe '.groq_available?' do
    context 'when API key is configured' do
      before do
        ENV['GROQ_API_KEY'] = 'test_api_key'
      end

      it 'returns true' do
        expect(described_class.groq_available?).to be true
      end
    end

    context 'when API key is not configured' do
      before do
        ENV.delete('GROQ_API_KEY')
      end

      it 'returns false' do
        expect(described_class.groq_available?).to be false
      end
    end

    context 'when API key is blank' do
      before do
        ENV['GROQ_API_KEY'] = ''
      end

      it 'returns false' do
        expect(described_class.groq_available?).to be false
      end
    end
  end
end

