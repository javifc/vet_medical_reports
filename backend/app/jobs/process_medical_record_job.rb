class ProcessMedicalRecordJob < ApplicationJob
  queue_as :default

  def perform(medical_record_id)
    medical_record = MedicalRecord.find(medical_record_id)
    
    # Update status to processing
    medical_record.update(status: :processing)

    # Extract text from document
    extraction_service = TextExtractionService.new(medical_record)
    extracted_text = extraction_service.extract

    # Parse and structure medical data
    parser_service = MedicalDataParserService.new(extracted_text)
    structured_data = parser_service.parse

    # Save extracted text and structured data
    medical_record.update(
      raw_text: extracted_text,
      structured_data: structured_data,
      pet_name: structured_data[:pet_name],
      species: structured_data[:species],
      breed: structured_data[:breed],
      age: structured_data[:age],
      owner_name: structured_data[:owner_name],
      diagnosis: structured_data[:diagnosis],
      treatment: structured_data[:treatment],
      status: :completed
    )

  rescue StandardError => e
    Rails.logger.error("Failed to process medical record #{medical_record_id}: #{e.message}")
    medical_record&.update(status: :failed) if medical_record
    raise
  end
end

