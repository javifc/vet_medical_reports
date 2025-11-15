class Api::V1::MedicalRecordsController < ApplicationController
  before_action :set_medical_record, only: [:show, :update]

  # GET /api/v1/medical_records
  def index
    @medical_records = MedicalRecord.recent
    render json: MedicalRecordBlueprint.render(@medical_records, view: :list)
  end

  # GET /api/v1/medical_records/:id
  def show
    render json: MedicalRecordBlueprint.render(@medical_record)
  end

  # POST /api/v1/medical_records/upload
  def upload
    unless params[:document].present?
      return render json: { error: 'Document is required' }, status: :unprocessable_entity
    end

    @medical_record = MedicalRecord.new(document: params[:document])

    if @medical_record.save
      # TODO: Trigger async processing job here
      render json: MedicalRecordBlueprint.render(@medical_record), status: :created
    else
      render json: { errors: @medical_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/medical_records/:id
  def update
    if @medical_record.update(medical_record_params)
      render json: MedicalRecordBlueprint.render(@medical_record)
    else
      render json: { errors: @medical_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_medical_record
    @medical_record = MedicalRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Medical record not found' }, status: :not_found
  end

  def medical_record_params
    # Only allow editing structured data, not the document itself
    params.permit(
      :pet_name,
      :species,
      :breed,
      :age,
      :owner_name,
      :diagnosis,
      :treatment,
      :notes
    )
  end
end
