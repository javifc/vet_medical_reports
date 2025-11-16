class ProcessMedicalRecordJob < ApplicationJob
  queue_as :default

  def perform(medical_record_id)
    medical_record = MedicalRecord.find(medical_record_id)
    medical_record.update(status: :processing)

    extracted_text = TextExtractionService.new(medical_record).extract
    structured_data = MedicalDataParserService.new(extracted_text).parse
    Rails.logger.info("JOB - Structured data: #{structured_data.inspect}")

    update_record_with_data(medical_record, extracted_text, structured_data)
  rescue StandardError => e
    handle_processing_error(medical_record, medical_record_id, e)
    raise
  end

  private

  def update_record_with_data(medical_record, extracted_text, structured_data)
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
  end

  def handle_processing_error(medical_record, medical_record_id, error)
    Rails.logger.error("Failed to process medical record #{medical_record_id}: #{error.message}")
    medical_record&.update(status: :failed)
  end
end
