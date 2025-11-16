# MedicalDataParserService
# Orchestrator service that decides whether to use AI-powered parsing (Groq)
# or rule-based parsing for extracting structured medical data from text.
#
# Strategy:
# 1. If Groq is available and returns sufficient fields (>= 3), use Groq
# 2. Otherwise, fall back to rule-based parsing
#
# Usage:
#   parser = MedicalDataParserService.new(raw_text)
#   structured_data = parser.parse
#
class MedicalDataParserService
  DEFAULT_MIN_FIELDS_FOR_GROQ = 3

  def initialize(raw_text)
    @raw_text = raw_text.to_s
  end

  def parse
    return {} if @raw_text.strip.empty?

    Rails.logger.info("\n#{'=' * 80}")
    Rails.logger.info('MEDICAL DATA PARSER - Starting')
    Rails.logger.info('=' * 80)

    groq_available = GroqStructuringService.groq_available?
    Rails.logger.info("PARSER - Groq available: #{groq_available}")

    if groq_available
      Rails.logger.info('PARSER - Using Groq for data structuring')
      groq_data = extract_with_groq
      Rails.logger.info("PARSER - Groq extracted #{groq_data.size} fields: #{groq_data.keys.inspect}")

      if groq_data.size >= DEFAULT_MIN_FIELDS_FOR_GROQ
        Rails.logger.info('PARSER - Groq data sufficient, returning')
        Rails.logger.info("#{'=' * 80}\n")
        return groq_data
      else
        Rails.logger.info(
          "PARSER - Groq data insufficient (#{groq_data.size} < #{DEFAULT_MIN_FIELDS_FOR_GROQ}), " \
          'falling back to rules'
        )
      end
    else
      Rails.logger.info('PARSER - Groq not available, using rule-based parsing')
    end

    Rails.logger.info('PARSER - Using rule-based parsing')
    structured_data = extract_with_rules
    Rails.logger.info("PARSER - Rule-based extracted #{structured_data.size} fields: #{structured_data.keys.inspect}")
    Rails.logger.info("#{'=' * 80}\n")
    structured_data
  end

  private

  # Extract structured data using Groq AI
  def extract_with_groq
    GroqStructuringService.new(@raw_text).structure
  rescue StandardError => e
    Rails.logger.error("Groq extraction failed: #{e.class} - #{e.message}")
    {}
  end

  # Extract structured data using rule-based parsing
  def extract_with_rules
    RuleBasedParserService.new(@raw_text).parse
  end
end
