#!/usr/bin/env ruby
# Integration Test 2: With Groq (AI + fallback to rules)

puts "=" * 80
puts "INTEGRATION TEST 2: WITH GROQ (AI + fallback to rules)"
puts "=" * 80
puts

# Ensure Groq is enabled for this test
ENV['GROQ_ENABLED'] = 'true'
puts "GROQ_ENABLED set to: #{ENV['GROQ_ENABLED']}"

# Check if Groq is available
groq_available = GroqStructuringService.groq_available?
puts "Groq API available: #{groq_available}"
if groq_available
  puts "Groq API URL: #{ENV['GROQ_API_URL']}"
  puts "Groq API Key: #{ENV['GROQ_API_KEY'] ? '[SET]' : '[NOT SET]'}"
else
  puts "WARNING: Groq is not available, test will fall back to rules"
end
puts

# Load test file
file_path = Rails.root.join('test_documents', 'medical_record_english.txt')
unless File.exist?(file_path)
  puts "ERROR: Test file not found at #{file_path}"
  exit 1
end

file_content = File.read(file_path)
puts "Document loaded (#{file_content.length} characters)"
puts "First 200 chars: #{file_content[0..200]}..."
puts

# Create record
puts "Creating medical record..."
record = MedicalRecord.new
record.status = :pending
record.raw_text = file_content
record.save(validate: false)
puts "Record created with ID: #{record.id}"
puts

# Parse data WITH Groq (or fallback to rules)
puts "Parsing data..."
if groq_available
  puts "Using Groq for AI-powered extraction..."
else
  puts "Groq unavailable, using rule-based parsing..."
end

parser = MedicalDataParserService.new(record.raw_text)
structured_data = parser.parse
puts

puts "Structured data extracted (#{structured_data.size} fields):"
structured_data.each do |key, value|
  display_value = value.to_s
  display_value = display_value[0..80] + "..." if display_value.length > 80
  puts "  #{key}: #{display_value}"
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
puts "  Age: #{record.age}"
puts "  Owner: #{record.owner_name}"
puts "  Veterinarian: #{record.structured_data[:veterinarian]}"
puts "  Diagnosis: #{record.diagnosis.to_s[0..60]}..." if record.diagnosis
puts

# Validation
if structured_data.size >= 6
  puts "=" * 80
  if groq_available
    puts "INTEGRATION TEST 2: PASSED ✓ (with Groq)"
  else
    puts "INTEGRATION TEST 2: PASSED ✓ (fallback to rules)"
  end
  puts "=" * 80
  
  # Additional check: verify key fields
  missing_fields = []
  [:pet_name, :species, :breed, :owner_name].each do |field|
    missing_fields << field unless structured_data[field]
  end
  
  if missing_fields.any?
    puts "WARNING: Some expected fields are missing: #{missing_fields.join(', ')}"
  else
    puts "All critical fields successfully extracted!"
  end
else
  puts "=" * 80
  puts "INTEGRATION TEST 2: FAILED (insufficient fields extracted: #{structured_data.size})"
  puts "=" * 80
  exit 1
end

