#!/usr/bin/env ruby
# Integration Test 1: Without Groq (Rule-based parsing only)

puts "=" * 80
puts "INTEGRATION TEST 1: WITHOUT GROQ (Rule-based parsing only)"
puts "=" * 80
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
puts "Creating medical record..."
record = MedicalRecord.new
record.status = :pending
record.raw_text = file_content
record.save(validate: false)
puts "Record created with ID: #{record.id}"
puts

# Parse data WITHOUT Groq (mock it as unavailable)
puts "Parsing data (rule-based only)..."
puts "Mocking Groq as unavailable..."

# Create a wrapper to force rule-based parsing
class TestParser < MedicalDataParserService
  def parse
    return {} if @raw_text.strip.empty?

    Rails.logger.info("\n" + "=" * 80)
    Rails.logger.info("TEST PARSER - Groq disabled for test")
    Rails.logger.info("=" * 80)
    Rails.logger.info("PARSER - Using rule-based parsing")
    
    structured_data = extract_with_rules
    compact = compact_hash(structured_data)
    Rails.logger.info("PARSER - Rule-based extracted #{compact.size} fields: #{compact.keys.inspect}")
    Rails.logger.info("=" * 80 + "\n")
    compact
  end
end

parser = TestParser.new(record.raw_text)
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

puts "Record updated:"
puts "  Status: #{record.status}"
puts "  Pet Name: #{record.pet_name}"
puts "  Species: #{record.species}"
puts "  Breed: #{record.breed}"
puts "  Owner: #{record.owner_name}"
puts "  Diagnosis: #{record.diagnosis.to_s[0..50]}..."
puts

if structured_data.size >= 5
  puts "=" * 80
  puts "INTEGRATION TEST 1: PASSED ✓"
  puts "=" * 80
else
  puts "=" * 80
  puts "INTEGRATION TEST 1: FAILED (insufficient fields extracted)"
  puts "=" * 80
  exit 1
end

