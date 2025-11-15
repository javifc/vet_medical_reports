require 'rails_helper'

RSpec.describe MedicalDataParserService do
  describe '#parse' do
    context 'with complete medical record text' do
      let(:raw_text) do
        <<~TEXT
          Veterinary Medical Record
          
          Patient Name: Max
          Species: Dog
          Breed: Golden Retriever
          Age: 5 years old
          Owner: John Smith
          Date: 2025-11-15
          Veterinarian: Dr. Jane Wilson
          
          Diagnosis:
          Acute gastroenteritis with mild dehydration.
          Possible dietary indiscretion.
          
          Treatment:
          - Fluid therapy (subcutaneous)
          - Metoclopramide 0.5mg/kg BID for 3 days
          - Bland diet for 5 days
          - Recheck in 3 days if symptoms persist
        TEXT
      end

      let(:service) { described_class.new(raw_text) }
      let(:result) { service.parse }

      it 'extracts pet name' do
        expect(result[:pet_name]).to eq('Max')
      end

      it 'extracts species' do
        expect(result[:species]).to eq('Dog')
      end

      it 'extracts breed' do
        expect(result[:breed]).to eq('Golden Retriever')
      end

      it 'extracts age' do
        expect(result[:age]).to eq('5 years old')
      end

      it 'extracts owner name' do
        expect(result[:owner_name]).to eq('John Smith')
      end

      it 'extracts diagnosis' do
        expect(result[:diagnosis]).to include('Acute gastroenteritis')
      end

      it 'extracts treatment' do
        expect(result[:treatment]).to include('Fluid therapy')
      end

      it 'extracts veterinarian' do
        expect(result[:veterinarian]).to eq('Dr. Jane Wilson')
      end

      it 'extracts date' do
        expect(result[:date]).to eq('2025-11-15')
      end
    end

    context 'with partial medical record text' do
      let(:raw_text) do
        <<~TEXT
          Pet: Luna
          Species: Cat
          
          Diagnosis: Upper respiratory infection
        TEXT
      end

      let(:service) { described_class.new(raw_text) }
      let(:result) { service.parse }

      it 'extracts available fields' do
        expect(result[:pet_name]).to eq('Luna')
        expect(result[:species]).to eq('Cat')
        expect(result[:diagnosis]).to include('Upper respiratory infection')
      end

      it 'does not include nil values' do
        expect(result).not_to have_key(:breed)
        expect(result).not_to have_key(:age)
      end
    end

    context 'with spanish text' do
      let(:raw_text) do
        <<~TEXT
          Nombre: Firulais
          Raza: Pastor Alemán
          Edad: 3 años
          Propietario: María García
          
          Diagnóstico: Otitis externa
          Tratamiento: Limpieza auricular y antibiótico tópico
        TEXT
      end

      let(:service) { described_class.new(raw_text) }
      let(:result) { service.parse }

      it 'extracts pet name' do
        expect(result[:pet_name]).to eq('Firulais')
      end

      it 'extracts breed' do
        expect(result[:breed]).to eq('Pastor Alemán')
      end

      it 'extracts age' do
        expect(result[:age]).to eq('3 años')
      end

      it 'extracts owner name' do
        expect(result[:owner_name]).to eq('María García')
      end

      it 'extracts diagnosis' do
        expect(result[:diagnosis]).to include('Otitis externa')
      end

      it 'extracts treatment' do
        expect(result[:treatment]).to include('Limpieza auricular')
      end
    end

    context 'with empty or nil text' do
      it 'returns empty hash for nil text' do
        service = described_class.new(nil)
        expect(service.parse).to eq({})
      end

      it 'returns empty hash for empty string' do
        service = described_class.new('')
        expect(service.parse).to eq({})
      end

      it 'returns empty hash for whitespace only' do
        service = described_class.new('   ')
        expect(service.parse).to eq({})
      end
    end

    context 'with unstructured text' do
      let(:raw_text) do
        "This is a random text with a Dog mentioned but no clear structure."
      end

      let(:service) { described_class.new(raw_text) }
      let(:result) { service.parse }

      it 'extracts species from free text' do
        expect(result[:species]).to eq('Dog')
      end

      it 'does not extract other fields' do
        expect(result[:pet_name]).to be_nil
        expect(result[:diagnosis]).to be_nil
      end
    end
  end
end

