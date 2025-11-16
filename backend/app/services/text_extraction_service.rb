class TextExtractionService
  class ExtractionError < StandardError; end

  def initialize(medical_record)
    @medical_record = medical_record
  end

  def extract
    return nil unless @medical_record.document.attached?

    Rails.logger.info("Starting text extraction for #{@medical_record.document.content_type}")

    result = case @medical_record.document.content_type
             when 'application/pdf'
               extract_from_pdf
             when %r{^image/(png|jpeg|jpg|webp)$}
               extract_from_image
             else
               # TODO: add word document extraction
               raise ExtractionError, "Unsupported file type: #{@medical_record.document.content_type}"
             end

    Rails.logger.info("Extraction completed, #{result&.length || 0} characters extracted")
    result
  rescue StandardError => e
    Rails.logger.error("Text extraction failed: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    raise ExtractionError, e.message
  end

  private

  def extract_from_pdf
    @medical_record.document.open do |file|
      reader = PDF::Reader.new(file.path)
      text = reader.pages.map(&:text).join("\n").strip

      # If PDF has no text (scanned image), try OCR
      if text.empty?
        Rails.logger.info('PDF has no text, attempting OCR on scanned PDF')
        return extract_with_ocr(file.path)
      end

      text
    rescue PDF::Reader::MalformedPDFError => e
      Rails.logger.error("Malformed PDF, attempting OCR: #{e.message}")
      # Try OCR as fallback for malformed PDFs
      extract_with_ocr(file.path)
    end
  rescue StandardError => e
    Rails.logger.error("PDF extraction failed: #{e.message}")
    ''
  end

  def extract_from_image
    @medical_record.document.open do |file|
      extract_with_ocr(file.path)
    end
  rescue StandardError => e
    Rails.logger.error("Image extraction failed: #{e.message}")
    ''
  end

  def extract_with_ocr(file_path)
    image = RTesseract.new(file_path)
    text = image.to_s.strip
    Rails.logger.info("OCR extracted #{text.length} characters")
    text
  rescue StandardError => e
    Rails.logger.error("OCR failed: #{e.message}")
    ''
  end
end
