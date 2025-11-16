#!/usr/bin/env ruby
# Integration Test 1: Without Groq (Rule-based parsing only)

# Load Rails environment
require_relative '../config/environment'

puts '=' * 80
puts 'INTEGRATION TEST 1: WITHOUT GROQ (Rule-based parsing only)'
puts '=' * 80
puts

# Disable Groq for this test
ENV['GROQ_ENABLED'] = 'false'
puts "GROQ_ENABLED set to: #{ENV.fetch('GROQ_ENABLED', nil)}"
puts "Groq available: #{GroqClient.available?}"
puts

# Simulate file upload
file_path = Rails.root.join('test_documents', 'medical_record_spanish.txt')
unless File.exist?(file_path)
  puts "ERROR: Test file not found at #{file_path}"
  exit 1
end

file_content = File.read(file_path)
puts "Document loaded (#{file_content.length} characters)"
puts

# Create record
puts 'Creating medical record...'
record = MedicalRecord.new
record.status = :pending
record.raw_text = file_content
record.save(validate: false)
puts "Record created with ID: #{record.id}"
puts

# Parse data using MedicalDataParserService (will use rule-based since Groq is disabled)
puts 'Parsing data via MedicalDataParserService...'
puts 'Expected to use rule-based parsing (Groq disabled)...'

parser = MedicalDataParserService.new(record.raw_text)
structured_data = parser.parse
puts

puts "Structured data extracted (#{structured_data.size} fields):"
structured_data.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Update record
record.structured_data = structured_data
record.pet_name = structured_data[:pet_name]
record.species = structured_data[:species]
record.breed = structured_data[:breed]
record.age = structured_data[:age]
record.owner_name = structured_data[:owner_name]
record.diagnosis = structured_data[:diagnosis]
record.treatment = structured_data[:treatment]
record.status = :completed
record.save(validate: false)

puts 'Record updated:'
puts "  Status: #{record.status}"
puts "  Pet Name: #{record.pet_name}"
puts "  Species: #{record.species}"
puts "  Breed: #{record.breed}"
puts "  Owner: #{record.owner_name}"
puts "  Diagnosis: #{record.diagnosis.to_s[0..50]}..."
puts

puts '=' * 80
if structured_data.size >= 5
  puts 'INTEGRATION TEST 1: PASSED ✓'
  puts '=' * 80
else
  puts 'INTEGRATION TEST 1: FAILED (insufficient fields extracted)'
  puts '=' * 80
  exit 1
end
