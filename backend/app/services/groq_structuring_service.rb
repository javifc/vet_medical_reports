require_relative '../../lib/groq_client'

class GroqStructuringService
  class StructuringError < StandardError; end

  def initialize(raw_text)
    @raw_text = raw_text
  end

  def structure
    return {} if @raw_text.blank?

    Rails.logger.info('=' * 80)
    Rails.logger.info("GROQ STRUCTURING - Starting for #{@raw_text.length} characters")
    Rails.logger.info('=' * 80)

    response_content = call_groq
    Rails.logger.info("GROQ RESPONSE: #{response_content[0..200]}...") if response_content

    parsed_data = parse_response(response_content)
    Rails.logger.info("PARSED DATA: #{parsed_data.inspect}")
    Rails.logger.info('=' * 80)

    Rails.logger.info("Groq structured #{parsed_data.keys.size} fields")
    parsed_data
  rescue GroqClient::RequestError, GroqClient::AuthenticationError, GroqClient::RateLimitError, StandardError => e
    Rails.logger.error("GROQ ERROR: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    {}
  end

  def self.groq_available?
    GroqClient.available?
  end

  private

  def groq_client
    @groq_client ||= GroqClient.new
  end

  def call_groq
    messages = [
      {
        role: 'system',
        content: 'You are a veterinary medical record parser. Extract information and return only valid JSON.'
      },
      {
        role: 'user',
        content: build_prompt
      }
    ]

    response = groq_client.chat_completion(
      messages: messages,
      model: 'llama-3.1-8b-instant',
      temperature: 0.1,
      max_tokens: 300
    )

    response.dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    raise StructuringError, "Groq request failed: #{e.message}"
  end

  def build_prompt
    <<~PROMPT
      Parse this veterinary medical record and return data in JSON format.

      Required fields: pet_name, species, breed, age, owner_name, diagnosis, treatment, veterinarian, date

      Medical record:
      #{@raw_text.truncate(1500)}

      Respond with JSON only:
    PROMPT
  end

  def parse_response(response)
    return {} if response.blank?

    # Extract JSON from response (sometimes LLM adds extra text)
    json_match = response.match(/\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/m)
    return {} unless json_match

    json_str = json_match[0]
    data = JSON.parse(json_str)

    # Handle nested JSON structures (flatten if needed)
    result = {}
    data.each do |key, value|
      if value.is_a?(Hash)
        # If value is a hash, merge its contents into result
        result.merge!(value.transform_keys(&:to_sym))
      else
        result[key.to_sym] = value
      end
    end

    # Filter out null values and keep only expected fields
    expected_fields = %i[pet_name species breed age owner_name diagnosis treatment veterinarian date]
    result.select { |k, v| expected_fields.include?(k) && !v.nil? && v != '' }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse Groq JSON response: #{e.message}")
    Rails.logger.error("Response was: #{response}")
    {}
  end
end
