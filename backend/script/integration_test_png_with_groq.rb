#!/usr/bin/env ruby
# Integration Test: PNG + OCR WITH Groq (AI-powered parsing + fallback)
#
# This test validates the COMPLETE flow with Groq:
# 1. Document upload and attachment
# 2. Job execution (ProcessMedicalRecordJob)
# 3. OCR text extraction from PNG
# 4. Groq AI-powered data structuring (with rule-based fallback)
# 5. Record update with extracted data
# 6. Specific field values match expected data
# 7. Comparison of Groq vs Rule-based results

require_relative '../config/environment'

# Expected values from the veterinary medical record PNG (vet_medical_record_sample.png)
# Based on actual content: Bella, a female Labrador Retriever owned by Naomi Ortiz
EXPECTED_DATA = {
  pet_name: 'Bella',
  species: 'Dog',              # OCR might extract as "og" or "Dog"
  breed: 'Labrador',           # Partial match (Labrador Retriever)
  age: '5',                    # 5 years / 03-14-2084
  owner_name: 'Naomi'          # Naomi Ortiz
}.freeze

REQUIRED_FIELDS = %i[pet_name species owner_name].freeze

def print_header(title)
  puts "\n#{'=' * 80}"
  puts title.center(80)
  puts '=' * 80
end

def print_section(title)
  puts "\n#{'-' * 80}"
  puts title
  puts '-' * 80
end

def validate_field(key, expected, actual)
  return false if actual.nil? || actual.to_s.strip.empty?

  actual_normalized = actual.to_s.downcase.strip
  expected_normalized = expected.to_s.downcase.strip
  actual_normalized.include?(expected_normalized)
end

def print_validation_results(record, expected_data, required_fields, method_name)
  all_passed = true
  matched_fields = []
  failed_fields = []
  missing_required = []

  print_section("VALIDATION RESULTS (#{method_name})")

  expected_data = expected_data.reject { |_k, v| v.to_s.strip.empty? }

  expected_data.each do |key, expected_value|
    actual_value = record.send(key)

    if actual_value.nil? || actual_value.to_s.strip.empty?
      status = required_fields.include?(key) ? '❌ MISSING (REQUIRED)' : '⚠️  MISSING (optional)'
      puts "#{status.ljust(25)} #{key}: expected to contain '#{expected_value}'"
      missing_required << key if required_fields.include?(key)
      failed_fields << key
      all_passed = false
    elsif validate_field(key, expected_value, actual_value)
      puts "#{'✅ MATCHED'.ljust(25)} #{key}: '#{actual_value}' (contains '#{expected_value}')"
      matched_fields << key
    else
      puts "#{'❌ INCORRECT'.ljust(25)} #{key}: expected '#{expected_value}', got '#{actual_value}'"
      failed_fields << key
      all_passed = false
    end
  end

  print_section("SUMMARY (#{method_name})")
  puts "Total fields extracted: #{matched_fields.size + failed_fields.size}"
  puts "Expected fields matched: #{matched_fields.size}/#{expected_data.size}"
  puts "Required fields missing: #{missing_required.size}/#{required_fields.size}"

  if missing_required.any?
    puts "\n❌ CRITICAL: Missing required fields: #{missing_required.join(', ')}"
  end

  [all_passed, matched_fields.size, missing_required.size]
end

def compare_with_rule_based(record, expected_data)
  print_section('COMPARISON WITH RULE-BASED PARSING')

  # Re-parse with rule-based only
  rule_parser = RuleBasedParserService.new(record.raw_text)
  rule_data = rule_parser.parse

  puts "Rule-based fields extracted: #{rule_data.keys.size}"
  puts "\nRule-based extracted data:"
  rule_data.each do |key, value|
    display_value = value.to_s.gsub(/\s+/, ' ').strip[0..60]
    puts "  - #{key.to_s.ljust(15)}: #{display_value}"
  end

  print_section('FIELD-BY-FIELD COMPARISON')
  expected_data.each_key do |key|
    groq_val = record.send(key).to_s.strip
    rule_val = rule_data[key].to_s.strip

    if groq_val == rule_val && !groq_val.empty?
      puts "#{'🤝 SAME'.ljust(15)} #{key}: '#{groq_val}'"
    elsif groq_val.empty? && !rule_val.empty?
      puts "#{'📊 RULES BETTER'.ljust(15)} #{key}: Groq=<empty>, Rules='#{rule_val}'"
    elsif !groq_val.empty? && rule_val.empty?
      puts "#{'🤖 GROQ BETTER'.ljust(15)} #{key}: Groq='#{groq_val}', Rules=<empty>"
    elsif !groq_val.empty? && !rule_val.empty?
      puts "#{'🔀 DIFFERENT'.ljust(15)} #{key}: Groq='#{groq_val}', Rules='#{rule_val}'"
    else
      puts "#{'⚪ BOTH EMPTY'.ljust(15)} #{key}"
    end
  end

  rule_data
end

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

print_header('INTEGRATION TEST: WITH GROQ')

# Enable Groq for this test
ENV['GROQ_ENABLED'] = 'true'
groq_available = GroqClient.available?

puts "GROQ_ENABLED: #{ENV.fetch('GROQ_ENABLED', nil)}"
puts "Groq API available: #{groq_available}"
if groq_available
  puts "Groq API URL: #{ENV.fetch('GROQ_API_URL', nil)}"
  puts "Groq API Key: #{ENV['GROQ_API_KEY'] ? '[SET]' : '[NOT SET]'}"
  puts 'Expected: AI-powered parsing via Groq'
else
  puts '⚠️  WARNING: Groq not available, will fall back to rule-based parsing'
end

# Load PNG fixture
print_section('1. CREATE MEDICAL RECORD WITH PNG')
file_path = Rails.root.join('spec', 'fixtures', 'files', 'vet_medical_record_sample.png')
unless File.exist?(file_path)
  puts "❌ ERROR: PNG file not found at #{file_path}"
  exit 1
end

puts "✅ PNG file found: #{file_path}"
puts "   File size: #{File.size(file_path)} bytes"

# Create user and medical record
user = User.first || User.create!(name: 'Test User', email: 'test@integration.com', password: 'password123')
record = MedicalRecord.new(user: user, status: :pending)
record.document.attach(
  io: File.open(file_path),
  filename: 'vet_medical_record_sample.png',
  content_type: 'image/png'
)

unless record.save
  puts "❌ ERROR: Failed to save record: #{record.errors.full_messages.join(', ')}"
  exit 1
end

puts "✅ Record created with ID: #{record.id}"
puts "   Initial status: #{record.status}"
puts "   Document attached: #{record.document.attached?}"

# Execute job synchronously (no Sidekiq delay)
print_section('2. EXECUTE JOB (ProcessMedicalRecordJob)')
puts 'Executing job synchronously...'

begin
  ProcessMedicalRecordJob.new.perform(record.id)
  puts "✅ Job completed successfully"
rescue StandardError => e
  puts "❌ ERROR: Job failed: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Reload record to get updated data
record.reload

# Verify job execution results
print_section('3. VERIFY JOB EXECUTION')
puts "Final status: #{record.status}"
puts "Raw text extracted: #{record.raw_text.present? ? "#{record.raw_text.length} characters" : 'NO'}"
puts "Structured data present: #{record.structured_data.present? ? 'YES' : 'NO'}"

if record.status != 'completed'
  puts "\n❌ ERROR: Job did not complete successfully (status: #{record.status})"
  exit 1
end

if record.raw_text.blank?
  puts "\n❌ ERROR: No text was extracted from document"
  exit 1
end

puts "\n✅ Job execution verified"

# Display extracted text sample
print_section('4. EXTRACTED TEXT (OCR)')
puts "Length: #{record.raw_text.length} characters"
puts "\nFirst 300 characters:"
puts "#{'-' * 76}"
puts record.raw_text[0..300].gsub("\n", "\n")
puts "#{'-' * 76}"

# Display structured data
print_section('5. EXTRACTED STRUCTURED DATA')
parsing_method = if groq_available && record.structured_data.present? && record.structured_data.size >= 3
                   'Groq AI'
                 else
                   'Rule-based (fallback)'
                 end

puts "Parsing method used: #{parsing_method}"

if record.structured_data.present?
  puts "Fields in structured_data: #{record.structured_data.keys.size}"
  record.structured_data.each do |key, value|
    display_value = value.to_s.gsub(/\s+/, ' ').strip
    display_value = "#{display_value[0..60]}..." if display_value.length > 60
    puts "  - #{key.to_s.ljust(15)}: #{display_value}"
  end
else
  puts "⚠️  No structured_data present"
end

puts "\nFields in record attributes:"
EXPECTED_DATA.keys.each do |key|
  value = record.send(key)
  display_value = value.to_s.gsub(/\s+/, ' ').strip
  display_value = "#{display_value[0..60]}..." if display_value.length > 60
  puts "  - #{key.to_s.ljust(15)}: #{display_value.empty? ? '<empty>' : display_value}"
end

# Validate extracted data against expected values
print_section('6. VALIDATE EXTRACTED DATA')
validation_passed, matched_count, missing_required_count = print_validation_results(
  record,
  EXPECTED_DATA,
  REQUIRED_FIELDS,
  parsing_method
)

# If Groq was available, compare with rule-based results
if groq_available
  rule_data = compare_with_rule_based(record, EXPECTED_DATA)

  # Count rule-based matches
  rule_matched = EXPECTED_DATA.count do |key, expected|
    validate_field(key, expected, rule_data[key])
  end

  print_section('PERFORMANCE COMPARISON')
  puts "#{parsing_method} matched fields: #{matched_count}/#{EXPECTED_DATA.reject { |_k, v| v.empty? }.size}"
  puts "Rule-based matched fields: #{rule_matched}/#{EXPECTED_DATA.reject { |_k, v| v.empty? }.size}"

  if matched_count > rule_matched
    puts "\n🏆 Winner: #{parsing_method} (#{matched_count - rule_matched} more field(s) matched)"
  elsif rule_matched > matched_count
    puts "\n🏆 Winner: Rule-based (#{rule_matched - matched_count} more field(s) matched)"
  else
    puts "\n🤝 Tie: Both methods matched the same number of fields"
  end
end

# Final result
print_header('TEST RESULT')
if validation_passed
  puts '✅ INTEGRATION TEST PASSED'.center(80)
  puts 'Flow with Groq completed successfully'.center(80)
  puts 'All required fields present and values match expected data'.center(80)
  if groq_available && matched_count >= 5
    puts ''
    puts '🚀 Groq AI significantly enhanced data extraction!'.center(80)
  end
  exit 0
else
  puts '❌ INTEGRATION TEST FAILED'.center(80)
  puts 'Some required fields are missing or values do not match'.center(80)
  exit 1
end
