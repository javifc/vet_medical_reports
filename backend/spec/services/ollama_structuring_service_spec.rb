require 'rails_helper'

RSpec.describe OllamaStructuringService do
  let(:sample_text) do
    <<~TEXT
      Pet Name: Max
      Species: Dog
      Breed: Golden Retriever
      Age: 5 years
      Owner: John Doe
      Diagnosis: Mild ear infection
      Treatment: Antibiotic drops
      Veterinarian: Dr. Smith
      Date: 2024-01-15
    TEXT
  end

  describe '#structure' do
    context 'when Ollama is available' do
      let(:ollama_response) do
        {
          'response' => JSON.generate({
            pet_name: 'Max',
            species: 'Dog',
            breed: 'Golden Retriever',
            age: '5 years',
            owner_name: 'John Doe',
            diagnosis: 'Mild ear infection',
            treatment: 'Antibiotic drops',
            veterinarian: 'Dr. Smith',
            date: '2024-01-15'
          })
        }.to_json
      end

      before do
        stub_request(:post, "#{ENV.fetch('OLLAMA_URL', 'http://localhost:11434')}/api/generate")
          .to_return(status: 200, body: ollama_response, headers: { 'Content-Type' => 'application/json' })
      end

      it 'extracts structured data using Ollama' do
        service = described_class.new(sample_text)
        result = service.structure

        expect(result).to be_a(Hash)
        expect(result[:pet_name]).to eq('Max')
        expect(result[:species]).to eq('Dog')
        expect(result[:breed]).to eq('Golden Retriever')
        expect(result[:age]).to eq('5 years')
        expect(result[:owner_name]).to eq('John Doe')
        expect(result[:diagnosis]).to eq('Mild ear infection')
        expect(result[:treatment]).to eq('Antibiotic drops')
        expect(result[:veterinarian]).to eq('Dr. Smith')
        expect(result[:date]).to eq('2024-01-15')
      end
    end

    context 'when Ollama returns malformed JSON' do
      before do
        stub_request(:post, "#{ENV.fetch('OLLAMA_URL', 'http://localhost:11434')}/api/generate")
          .to_return(status: 200, body: { response: 'invalid json' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns empty hash' do
        service = described_class.new(sample_text)
        result = service.structure

        expect(result).to eq({})
      end
    end

    context 'when Ollama API is unavailable' do
      before do
        stub_request(:post, "#{ENV.fetch('OLLAMA_URL', 'http://localhost:11434')}/api/generate")
          .to_timeout
      end

      it 'returns empty hash' do
        service = described_class.new(sample_text)
        result = service.structure

        expect(result).to eq({})
      end
    end

    context 'when raw text is blank' do
      it 'returns empty hash' do
        service = described_class.new('')
        result = service.structure

        expect(result).to eq({})
      end
    end

    context 'when Ollama response includes extra text' do
      let(:ollama_response_with_text) do
        {
          'response' => "Here is the extracted data:\n#{JSON.generate({ pet_name: 'Max', species: 'Dog' })}\nHope this helps!"
        }.to_json
      end

      before do
        stub_request(:post, "#{ENV.fetch('OLLAMA_URL', 'http://localhost:11434')}/api/generate")
          .to_return(status: 200, body: ollama_response_with_text, headers: { 'Content-Type' => 'application/json' })
      end

      it 'extracts JSON from response text' do
        service = described_class.new(sample_text)
        result = service.structure

        expect(result[:pet_name]).to eq('Max')
        expect(result[:species]).to eq('Dog')
      end
    end
  end
end

