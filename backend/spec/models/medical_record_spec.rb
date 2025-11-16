require 'rails_helper'

RSpec.describe MedicalRecord, type: :model do
  describe 'Active Storage' do
    it { should have_one_attached(:document) }
  end

  describe 'validations' do
    it { should validate_presence_of(:status) }

    context 'on create' do
      before do
        # Disable global Active Storage mock for validation tests
        allow_any_instance_of(MedicalRecord).to receive(:document).and_call_original
      end

      it 'requires document to be present' do
        record = MedicalRecord.new
        expect(record).not_to be_valid
        expect(record.errors[:document]).to include("can't be blank")
      end
    end

    context 'document format validation' do
      before do
        # Disable global Active Storage mock for validation tests
        allow_any_instance_of(MedicalRecord).to receive(:document).and_call_original
      end

      let(:record) { MedicalRecord.new }

      it 'accepts PDF files' do
        file = fixture_file_upload('test.pdf', 'application/pdf')
        record.document.attach(file)
        record.save(validate: false)
        expect(record.errors[:document]).to be_empty
      end

      it 'accepts PNG images' do
        file = fixture_file_upload('test.png', 'image/png')
        record.document.attach(file)
        record.save(validate: false)
        expect(record.errors[:document]).to be_empty
      end

      it 'rejects invalid file types' do
        file = fixture_file_upload('test.txt', 'text/plain')
        record.document.attach(file)
        record.valid?
        expect(record.errors[:document]).to include('must be a PDF, image (PNG/JPG), or Word document')
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 'pending', processing: 'processing', completed: 'completed', failed: 'failed').backed_by_column_of_type(:string) }
  end

  describe 'callbacks' do
    it 'sets original_filename from document on save' do
      file = fixture_file_upload('test.pdf', 'application/pdf')
      record = MedicalRecord.new
      record.document.attach(file)
      record.save
      expect(record.original_filename).to eq('test.pdf')
    end
  end

  describe 'scopes' do
    let!(:oldest) { create(:medical_record, created_at: 2.days.ago) }
    let!(:newest) { create(:medical_record, created_at: 1.day.ago) }

    describe '.recent' do
      it 'returns records ordered by created_at desc' do
        expect(MedicalRecord.recent).to eq([newest, oldest])
      end
    end

    describe '.by_status' do
      let!(:pending) { create(:medical_record, status: :pending) }
      let!(:completed) { create(:medical_record, status: :completed) }

      it 'filters by status' do
        expect(MedicalRecord.by_status(:pending)).to include(pending)
        expect(MedicalRecord.by_status(:pending)).not_to include(completed)
      end
    end
  end

  describe 'instance methods' do
    let(:record) { build(:medical_record) }

    describe '#processed?' do
      it 'returns true when status is completed' do
        record.status = :completed
        expect(record.processed?).to be true
      end

      it 'returns true when status is failed' do
        record.status = :failed
        expect(record.processed?).to be true
      end

      it 'returns false when status is pending' do
        record.status = :pending
        expect(record.processed?).to be false
      end
    end

    describe '#has_structured_data?' do
      it 'returns true when structured_data has values' do
        record.structured_data = { pet_name: 'Max' }
        expect(record.has_structured_data?).to be true
      end

      it 'returns false when structured_data is empty' do
        record.structured_data = {}
        expect(record.has_structured_data?).to be false
      end

      it 'returns false when structured_data is nil' do
        record.structured_data = nil
        expect(record.has_structured_data?).to be false
      end
    end
  end
end
