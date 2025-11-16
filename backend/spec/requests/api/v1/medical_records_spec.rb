require 'rails_helper'

RSpec.describe 'Api::V1::MedicalRecords', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  let(:valid_pdf) do
    double('file',
           original_filename: 'test.pdf',
           content_type: 'application/pdf',
           read: 'fake pdf content',
           size: 1024,
           path: '/tmp/test.pdf')
  end

  let(:invalid_file) do
    double('file',
           original_filename: 'test.txt',
           content_type: 'text/plain',
           read: 'fake content',
           size: 1024,
           path: '/tmp/test.txt')
  end

  describe 'POST /api/v1/medical_records/upload' do
    context 'with valid document' do
      it 'creates a new medical record and enqueues processing job' do
        # Mock record and its behaviors
        record = build(:medical_record, user: user)
        allow(record).to receive_messages(save: true, id: 1)

        # Mock the association chain current_user.medical_records.new
        medical_records_association = double('ActiveRecord::Associations::CollectionProxy')
        allow_any_instance_of(User).to receive(:medical_records).and_return(medical_records_association)
        allow(medical_records_association).to receive(:new).with(hash_including(:document)).and_return(record)

        # Verify job is enqueued (not executed) - controller passes ID
        expect(ProcessMedicalRecordJob).to receive(:perform_later).with(1)

        expect do
          post upload_api_v1_medical_records_path, params: { document: valid_pdf }, headers: headers
        end.not_to change(MedicalRecord, :count)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['status']).to eq('pending')
      end
    end

    context 'without document' do
      it 'returns error' do
        post upload_api_v1_medical_records_path, params: {}, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to eq('Document is required')
      end
    end

    context 'with invalid document type' do
      it 'returns validation error' do
        # Mock MedicalRecord with validation errors
        mock_errors = double('errors', full_messages: ['Document must be a PDF, image (PNG/JPG), or Word document'])
        mock_record = instance_double(MedicalRecord,
                                      save: false,
                                      valid?: false,
                                      errors: mock_errors,
                                      new_record?: true)

        # Mock the association chain current_user.medical_records.new
        medical_records_association = double('ActiveRecord::Associations::CollectionProxy')
        allow_any_instance_of(User).to receive(:medical_records).and_return(medical_records_association)
        allow(medical_records_association).to receive(:new).with(hash_including(:document)).and_return(mock_record)

        post upload_api_v1_medical_records_path, params: { document: invalid_file }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['errors']).to include('Document must be a PDF, image (PNG/JPG), or Word document')
      end
    end
  end

  describe 'GET /api/v1/medical_records' do
    let!(:record1) { create(:medical_record, user: user, created_at: 1.day.ago) }
    let!(:record2) { create(:medical_record, user: user, created_at: 2.days.ago) }

    it 'returns all medical records ordered by most recent' do
      get api_v1_medical_records_path, headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(2)
      expect(json.first['id']).to eq(record1.id)
      expect(json.second['id']).to eq(record2.id)
    end
  end

  describe 'GET /api/v1/medical_records/:id' do
    let(:record) { create(:medical_record, :with_data, user: user) }

    context 'when record exists' do
      it 'returns the medical record' do
        get api_v1_medical_record_path(record), headers: headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['id']).to eq(record.id)
        expect(json['pet_name']).to eq('Max')
        expect(json['species']).to eq('Dog')
      end
    end

    context 'when record does not exist' do
      it 'returns not found error' do
        get api_v1_medical_record_path(id: 999_999), headers: headers

        expect(response).to have_http_status(:not_found)
        json = response.parsed_body
        expect(json['error']).to eq('Medical record not found')
      end
    end
  end

  describe 'PATCH /api/v1/medical_records/:id' do
    let(:record) { create(:medical_record, user: user) }

    context 'with valid params' do
      let(:valid_params) do
        {
          pet_name: 'Buddy',
          species: 'Cat',
          diagnosis: 'Updated diagnosis'
        }
      end

      it 'updates the medical record' do
        patch api_v1_medical_record_path(record),
              params: valid_params,
              headers: headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['pet_name']).to eq('Buddy')
        expect(json['species']).to eq('Cat')
        expect(json['diagnosis']).to eq('Updated diagnosis')

        record.reload
        expect(record.pet_name).to eq('Buddy')
      end
    end

    context 'when record does not exist' do
      it 'returns not found error' do
        patch api_v1_medical_record_path(id: 999_999),
              params: { pet_name: 'Test' },
              headers: headers,
              as: :json

        expect(response).to have_http_status(:not_found)
        json = response.parsed_body
        expect(json['error']).to eq('Medical record not found')
      end
    end

    context 'attempting to update document' do
      it 'ignores document parameter' do
        original_filename = record.original_filename

        patch api_v1_medical_record_path(record),
              params: { document: valid_pdf },
              headers: headers,
              as: :json

        record.reload
        expect(record.original_filename).to eq(original_filename)
      end
    end
  end
end
