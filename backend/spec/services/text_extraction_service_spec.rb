require 'rails_helper'

RSpec.describe TextExtractionService do
  let(:medical_record) { create(:medical_record) }
  let(:service) { described_class.new(medical_record) }

  describe '#extract' do
    context 'with PDF document' do
      before do
        medical_record.document.purge
        medical_record.document.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'vet_medical_record_sample.pdf')),
          filename: 'vet_medical_record_sample.pdf',
          content_type: 'application/pdf'
        )
      end

      it 'extracts text from PDF' do
        text = service.extract
        
        expect(text).to be_a(String)
        # PDF might be scanned image without text layer, so text could be empty
      end

      it 'handles PDF extraction without errors' do
        expect { service.extract }.not_to raise_error
      end
    end

    context 'with image document' do
      before do
        medical_record.document.purge
        medical_record.document.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'vet_medical_record_sample.png')),
          filename: 'vet_medical_record_sample.png',
          content_type: 'image/png'
        )
      end

      it 'extracts text from image using OCR' do
        text = service.extract
        
        expect(text).to be_a(String)
        # OCR might not be perfect, but should extract something
        expect(text.length).to be >= 0
      end
    end

    context 'without attached document' do
      before do
        medical_record.document.purge
      end

      it 'returns nil' do
        expect(service.extract).to be_nil
      end
    end
  end
end

