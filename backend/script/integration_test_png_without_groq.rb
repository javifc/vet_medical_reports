#!/usr/bin/env ruby
# Integration Test 1: PNG with OCR - Without Groq (Rule-based parsing only)

puts "=" * 80
puts "INTEGRATION TEST 1: PNG + OCR WITHOUT GROQ"
puts "=" * 80
puts

# Load PNG file
file_path = Rails.root.join('spec', 'fixtures', 'files', 'vet_medical_record_sample.png')
unless File.exist?(file_path)
  puts "ERROR: PNG file not found at #{file_path}"
  exit 1
end

puts "PNG file found: #{file_path}"
puts "File size: #{File.size(file_path)} bytes"
puts

# Create record and attach PNG
puts "Creating medical record with PNG attachment..."
record = MedicalRecord.new(status: :pending)

# Attach the PNG file
record.document.attach(
  io: File.open(file_path),
  filename: 'vet_medical_record_sample.png',
  content_type: 'image/png'
)

unless record.save
  puts "ERROR: Failed to save record: #{record.errors.full_messages.join(', ')}"
  exit 1
end

puts "Record created with ID: #{record.id}"
puts "Document attached: #{record.document.attached?}"
puts "Document filename: #{record.document.filename}"
puts "Document content_type: #{record.document.content_type}"
puts

# Extract text using OCR
puts "Extracting text from PNG using OCR..."
extractor = TextExtractionService.new(record)
raw_text = extractor.extract

if raw_text.nil? || raw_text.strip.empty?
  puts "ERROR: No text extracted from PNG"
  exit 1
end

puts "Text extracted successfully!"
puts "Raw text length: #{raw_text.length} characters"
puts "First 300 chars:"
puts "-" * 80
puts raw_text[0..300]
puts "-" * 80
puts

# Save raw text
record.raw_text = raw_text
record.status = :processing
record.save

# Parse data WITHOUT Groq (force rule-based parsing)
puts "Parsing data (rule-based only - Groq disabled)..."

class TestParserNoGroq < MedicalDataParserService
  def parse
    return {} if @raw_text.strip.empty?
    
    puts "Using RULE-BASED parsing..."
    structured_data = extract_with_rules
    compact_hash(structured_data)
  end
end

parser = TestParserNoGroq.new(record.raw_text)
structured_data = parser.parse
puts

puts "Structured data extracted (#{structured_data.size} fields):"
structured_data.each do |key, value|
  display_value = value.to_s.gsub(/\s+/, ' ').strip
  display_value = display_value[0..80] + "..." if display_value.length > 80
  puts "  #{key}: #{display_value}"
end
puts

# Update record with structured data
record.structured_data = structured_data
record.pet_name = structured_data[:pet_name]
record.species = structured_data[:species]
record.breed = structured_data[:breed]
record.age = structured_data[:age]
record.owner_name = structured_data[:owner_name]
record.diagnosis = structured_data[:diagnosis]
record.treatment = structured_data[:treatment]
record.status = :completed
record.save

puts "Final record state:"
puts "  ID: #{record.id}"
puts "  Status: #{record.status}"
puts "  Original filename: #{record.original_filename}"
puts "  Pet Name: #{record.pet_name || '[not extracted]'}"
puts "  Species: #{record.species || '[not extracted]'}"
puts "  Breed: #{record.breed || '[not extracted]'}"
puts "  Owner: #{record.owner_name || '[not extracted]'}"
puts

# Validation
min_fields = 3
if structured_data.size >= min_fields
  puts "=" * 80
  puts "INTEGRATION TEST 1: PASSED ✓"
  puts "Extracted #{structured_data.size} fields from PNG using OCR + rule-based parsing"
  puts "=" * 80
else
  puts "=" * 80
  puts "INTEGRATION TEST 1: FAILED"
  puts "Only #{structured_data.size} fields extracted (minimum: #{min_fields})"
  puts "=" * 80
  exit 1
end

