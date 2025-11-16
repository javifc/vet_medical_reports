require 'net/http'
require 'uri'
require 'json'

class GroqClient
  class RequestError < StandardError; end
  class AuthenticationError < StandardError; end
  class RateLimitError < StandardError; end

  DEFAULT_URL = 'https://api.groq.com/openai/v1/chat/completions'.freeze
  DEFAULT_TIMEOUT = 30

  def initialize(api_key: nil, url: nil, timeout: nil)
    @api_key = api_key || ENV.fetch('GROQ_API_KEY', nil)
    @url = url || ENV.fetch('GROQ_API_URL', DEFAULT_URL)
    @timeout = timeout || DEFAULT_TIMEOUT

    raise AuthenticationError, 'Groq API key is required' if @api_key.blank?
  end

  def chat_completion(messages:, model: 'llama-3.1-8b-instant', temperature: 0.1, max_tokens: 300)
    uri = URI.parse(@url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = @timeout

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = build_request_body(messages, model, temperature, max_tokens).to_json

    response = http.request(request)
    handle_response(response)
  rescue Net::ReadTimeout => e
    raise RequestError, "Request timed out after #{@timeout} seconds: #{e.message}"
  rescue StandardError => e
    raise RequestError, "Request failed: #{e.message}"
  end

  def self.available?
    enabled = ENV.fetch('GROQ_ENABLED', 'true').to_s.downcase
    return false if enabled != 'true'

    api_key = ENV.fetch('GROQ_API_KEY', nil)
    api_key.present?
  rescue StandardError => e
    Rails.logger.warn("GroqClient availability check failed: #{e.message}") if defined?(Rails)
    false
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@api_key}"
    }
  end

  def build_request_body(messages, model, temperature, max_tokens)
    {
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens
    }
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      parse_success_response(response)
    when Net::HTTPUnauthorized
      raise AuthenticationError, "Invalid API key: #{response.body}"
    when Net::HTTPTooManyRequests
      raise RateLimitError, "Rate limit exceeded: #{response.body}"
    else
      raise RequestError, "Groq API returned #{response.code}: #{response.body}"
    end
  end

  def parse_success_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise RequestError, "Failed to parse Groq response: #{e.message}"
  end
end
