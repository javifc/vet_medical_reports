require 'net/http'
require 'uri'
require 'json'

class OllamaStructuringService
  class StructuringError < StandardError; end

  def initialize(raw_text)
    @raw_text = raw_text
  end

  def structure
    return {} if @raw_text.blank?

    Rails.logger.info("=" * 80)
    Rails.logger.info("OLLAMA STRUCTURING - Starting for #{@raw_text.length} characters")
    Rails.logger.info("=" * 80)
    
    response = call_ollama
    Rails.logger.info("OLLAMA RESPONSE: #{response[0..200]}...") if response
    
    parsed_data = parse_response(response)
    Rails.logger.info("PARSED DATA: #{parsed_data.inspect}")
    Rails.logger.info("=" * 80)
    
    Rails.logger.info("Ollama structured #{parsed_data.keys.size} fields")
    parsed_data
  rescue => e
    Rails.logger.error("OLLAMA ERROR: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    {}
  end

  def self.ollama_available?
    # Check if Ollama URL is configured
    ollama_url = ENV.fetch('OLLAMA_URL', nil)
    Rails.logger.info("OLLAMA CHECK - URL: #{ollama_url.inspect}")
    
    if ollama_url.blank?
      Rails.logger.info("OLLAMA CHECK - URL is blank, returning false")
      return false
    end
    
    # Quick health check (with short timeout)
    uri = URI.parse("#{ollama_url}/api/tags")
    Rails.logger.info("OLLAMA CHECK - Connecting to: #{uri}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 2
    http.open_timeout = 2
    
    response = http.get(uri.path)
    success = response.is_a?(Net::HTTPSuccess)
    Rails.logger.info("OLLAMA CHECK - Response: #{response.code}, Success: #{success}")
    success
  rescue => e
    Rails.logger.warn("OLLAMA CHECK - Error: #{e.class} - #{e.message}")
    false
  end

  private

  def call_ollama
    url = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
    uri = URI.parse("#{url}/api/generate")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 120  # Increased timeout for slower LLM processing
    
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
      request.body = {
        model: 'tinyllama',
        prompt: build_prompt,
        stream: false,
        options: {
          temperature: 0.1,
          top_p: 0.9,
          num_predict: 200,  # Limit response to 200 tokens (enough for JSON)
          num_ctx: 1024      # Smaller context window for faster processing
        }
      }.to_json
    
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise StructuringError, "Ollama API returned #{response.code}: #{response.body}"
    end
    
    JSON.parse(response.body)['response']
  rescue JSON::ParserError => e
    raise StructuringError, "Failed to parse Ollama response: #{e.message}"
  rescue => e
    raise StructuringError, "Ollama request failed: #{e.message}"
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
    expected_fields = [:pet_name, :species, :breed, :age, :owner_name, :diagnosis, :treatment, :veterinarian, :date]
    result.select { |k, v| expected_fields.include?(k) && !v.nil? }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse Ollama JSON response: #{e.message}")
    Rails.logger.error("Response was: #{response}")
    {}
  end
end

