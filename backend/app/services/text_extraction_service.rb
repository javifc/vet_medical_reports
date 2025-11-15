class TextExtractionService
  class ExtractionError < StandardError; end

  def initialize(medical_record)
    @medical_record = medical_record
  end

  def extract
    return nil unless @medical_record.document.attached?

    case @medical_record.document.content_type
    when 'application/pdf'
      extract_from_pdf
    when /^image\/(png|jpeg|jpg|webp)$/
      extract_from_image
    else
      raise ExtractionError, "Unsupported file type: #{@medical_record.document.content_type}"
    end
  rescue => e
    Rails.logger.error("Text extraction failed: #{e.message}")
    raise ExtractionError, e.message
  end

  private

  def extract_from_pdf
    @medical_record.document.open do |file|
      reader = PDF::Reader.new(file.path)
      text = reader.pages.map(&:text).join("\n")
      text.strip
    end
  end

  def extract_from_image
    @medical_record.document.open do |file|
      image = RTesseract.new(file.path)
      text = image.to_s
      text.strip
    end
  rescue => e
    Rails.logger.error("OCR failed: #{e.message}")
    # If OCR fails, return empty string instead of raising
    ""
  end
end

