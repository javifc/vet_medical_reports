#!/usr/bin/env ruby
# Integration Test: PNG + OCR WITHOUT Groq (Rule-based parsing only)
#
# This test validates the COMPLETE flow without Groq:
# 1. Document upload and attachment
# 2. Job execution (ProcessMedicalRecordJob)
# 3. OCR text extraction from PNG
# 4. Rule-based data structuring
# 5. Record update with extracted data
# 6. Specific field values match expected data

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

  # Normalize for comparison (lowercase, strip whitespace)
  actual_normalized = actual.to_s.downcase.strip
  expected_normalized = expected.to_s.downcase.strip

  # Check if actual contains expected (flexible matching)
  actual_normalized.include?(expected_normalized)
end

def print_validation_results(record, expected_data, required_fields)
  all_passed = true
  matched_fields = []
  failed_fields = []
  missing_required = []

  print_section('VALIDATION RESULTS')

  # Filter out empty expected values (optional fields not in document)
  expected_data = expected_data.reject { |_k, v| v.to_s.strip.empty? }

  # Check all expected fields
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

  print_section('SUMMARY')
  puts "Total fields extracted: #{matched_fields.size + failed_fields.size}"
  puts "Expected fields matched: #{matched_fields.size}/#{expected_data.size}"
  puts "Required fields missing: #{missing_required.size}/#{required_fields.size}"

  if missing_required.any?
    puts "\n❌ CRITICAL: Missing required fields: #{missing_required.join(', ')}"
  end

  all_passed
end

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

print_header('INTEGRATION TEST: WITHOUT GROQ')

# Disable Groq for this test
ENV['GROQ_ENABLED'] = 'false'
puts "GROQ_ENABLED: #{ENV.fetch('GROQ_ENABLED', nil)}"
puts "Groq available: #{GroqClient.available?}"
puts 'Expected: Rule-based parsing only'

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
validation_passed = print_validation_results(record, EXPECTED_DATA, REQUIRED_FIELDS)

# Final result
print_header('TEST RESULT')
if validation_passed
  puts '✅ INTEGRATION TEST PASSED'.center(80)
  puts 'Flow without Groq completed successfully'.center(80)
  puts 'All required fields present and values match expected data'.center(80)
  exit 0
else
  puts '❌ INTEGRATION TEST FAILED'.center(80)
  puts 'Some required fields are missing or values do not match'.center(80)
  exit 1
end
