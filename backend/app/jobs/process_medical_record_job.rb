class ProcessMedicalRecordJob < ApplicationJob
  queue_as :default

  def perform(medical_record_id)
    medical_record = MedicalRecord.find(medical_record_id)
    
    # Update status to processing
    medical_record.update(status: :processing)

    # Extract text from document
    extraction_service = TextExtractionService.new(medical_record)
    extracted_text = extraction_service.extract

    # Save extracted text
    medical_record.update(
      raw_text: extracted_text,
      status: :completed
    )

  rescue StandardError => e
    Rails.logger.error("Failed to process medical record #{medical_record_id}: #{e.message}")
    medical_record&.update(status: :failed) if medical_record
    raise
  end
end

