# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating test user..."

user = User.find_or_initialize_by(email: 'test@example.com')
user.assign_attributes(
  name: 'Test User',
  password: 'password123',
  password_confirmation: 'password123'
)

if user.save
  puts "✓ User created: #{user.email}"
  puts "  Name: #{user.name}"
  puts "  Password: password123"
else
  puts "✗ Error creating user: #{user.errors.full_messages.join(', ')}"
end

puts "\nSeeds completed!"
puts "\nYou can now login with:"
puts "  Email: test@example.com"
puts "  Password: password123"
