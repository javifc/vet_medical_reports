require 'rails_helper'

RSpec.describe "Api::V1::MedicalRecords", type: :request do
  let(:valid_pdf) { fixture_file_upload('test.pdf', 'application/pdf') }
  let(:invalid_file) { fixture_file_upload('test.txt', 'text/plain') }

  describe "POST /api/v1/medical_records/upload" do
    context "with valid document" do
      it "creates a new medical record" do
        expect {
          post upload_api_v1_medical_records_path, params: { document: valid_pdf }
        }.to change(MedicalRecord, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('pending')
        expect(json['original_filename']).to eq('test.pdf')
      end
    end

    context "without document" do
      it "returns error" do
        post upload_api_v1_medical_records_path, params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Document is required')
      end
    end

    context "with invalid document type" do
      it "returns validation error" do
        post upload_api_v1_medical_records_path, params: { document: invalid_file }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Document must be a PDF, image (PNG/JPG), or Word document')
      end
    end
  end

  describe "GET /api/v1/medical_records" do
    let!(:record1) { create(:medical_record, created_at: 1.day.ago) }
    let!(:record2) { create(:medical_record, created_at: 2.days.ago) }

    it "returns all medical records ordered by most recent" do
      get api_v1_medical_records_path

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json.first['id']).to eq(record1.id)
      expect(json.second['id']).to eq(record2.id)
    end
  end

  describe "GET /api/v1/medical_records/:id" do
    let(:record) { create(:medical_record, :with_data) }

    context "when record exists" do
      it "returns the medical record" do
        get api_v1_medical_record_path(record)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(record.id)
        expect(json['pet_name']).to eq('Max')
        expect(json['species']).to eq('Dog')
      end
    end

    context "when record does not exist" do
      it "returns not found error" do
        get api_v1_medical_record_path(id: 999999)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Medical record not found')
      end
    end
  end

  describe "PATCH /api/v1/medical_records/:id" do
    let(:record) { create(:medical_record) }

    context "with valid params" do
      let(:valid_params) do
        {
          pet_name: 'Buddy',
          species: 'Cat',
          diagnosis: 'Updated diagnosis'
        }
      end

      it "updates the medical record" do
        patch api_v1_medical_record_path(record), 
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pet_name']).to eq('Buddy')
        expect(json['species']).to eq('Cat')
        expect(json['diagnosis']).to eq('Updated diagnosis')

        record.reload
        expect(record.pet_name).to eq('Buddy')
      end
    end

    context "when record does not exist" do
      it "returns not found error" do
        patch api_v1_medical_record_path(id: 999999),
              params: { pet_name: 'Test' },
              as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Medical record not found')
      end
    end

    context "attempting to update document" do
      it "ignores document parameter" do
        original_filename = record.original_filename
        
        patch api_v1_medical_record_path(record),
              params: { document: valid_pdf },
              as: :json

        record.reload
        expect(record.original_filename).to eq(original_filename)
      end
    end
  end
end
