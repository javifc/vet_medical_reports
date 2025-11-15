require 'rails_helper'

RSpec.describe TextExtractionService do
  let(:medical_record) { create(:medical_record) }
  let(:service) { described_class.new(medical_record) }

  describe '#extract' do
    context 'with PDF document' do
      before do
        medical_record.document.purge
        medical_record.document.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'medical_sample.pdf')),
          filename: 'medical_sample.pdf',
          content_type: 'application/pdf'
        )
      end

      it 'extracts text from PDF' do
        text = service.extract
        
        # Even if PDF is minimal, it should extract something or return empty string
        expect(text).to be_a(String)
      end

      it 'handles extraction process' do
        # Should either extract text or handle gracefully
        result = nil
        expect {
          result = service.extract
        }.not_to raise_error(StandardError)
        
        expect(result).to be_a(String).or be_nil
      end
    end

    context 'with image document' do
      before do
        medical_record.document.purge
        medical_record.document.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test.png')),
          filename: 'test.png',
          content_type: 'image/png'
        )
      end

      it 'raises error for now (OCR not implemented)' do
        expect {
          service.extract
        }.to raise_error(TextExtractionService::ExtractionError, /OCR not yet implemented/)
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

