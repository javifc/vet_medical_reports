require 'rails_helper'

RSpec.describe TextExtractionService do
  let(:medical_record) { build(:medical_record) }
  let(:service) { described_class.new(medical_record) }

  describe '#extract' do
    context 'with PDF document' do
      let(:mock_file) do
        double('File',
               path: '/tmp/fake.pdf',
               read: 'fake content',
               close: nil)
      end

      before do
        # Mock the document attachment with open support
        mock_attachment = double('attachment',
                                 attached?: true,
                                 content_type: 'application/pdf',
                                 filename: 'test.pdf')

        allow(mock_attachment).to receive(:open).and_yield(mock_file)
        allow(medical_record).to receive(:document).and_return(mock_attachment)

        # Mock PDF::Reader
        pdf_reader = double('PDF::Reader')
        pdf_page = double('page', text: 'Extracted text from PDF\nPet Name: Bella\nSpecies: Dog')
        allow(PDF::Reader).to receive(:new).and_return(pdf_reader)
        allow(pdf_reader).to receive(:pages).and_return([pdf_page])
      end

      it 'extracts text from PDF using PDF::Reader' do
        text = service.extract

        expect(text).to be_a(String)
        expect(text).to include('Extracted text from PDF')
      end

      it 'handles PDF extraction without errors' do
        expect { service.extract }.not_to raise_error
      end
    end

    context 'with image document' do
      let(:mock_image_file) do
        double('File',
               path: '/tmp/fake.png',
               read: 'fake image content',
               close: nil)
      end

      before do
        # Mock the document attachment with open support
        mock_attachment = double('attachment',
                                 attached?: true,
                                 content_type: 'image/png',
                                 filename: 'test.png')

        allow(mock_attachment).to receive(:open).and_yield(mock_image_file)
        allow(medical_record).to receive(:document).and_return(mock_attachment)

        # Mock RTesseract
        tesseract = double('RTesseract')
        allow(RTesseract).to receive(:new).and_return(tesseract)
        allow(tesseract).to receive(:to_s).and_return('Extracted text from image via OCR\nAnimal Name: Bella')
      end

      it 'extracts text from image using OCR' do
        text = service.extract

        expect(text).to be_a(String)
        expect(text).to include('Extracted text from image')
      end
    end

    context 'without attached document' do
      before do
        mock_attachment = double('attachment', attached?: false)
        allow(medical_record).to receive(:document).and_return(mock_attachment)
      end

      it 'returns nil' do
        expect(service.extract).to be_nil
      end
    end
  end
end
