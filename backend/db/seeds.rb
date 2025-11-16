# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.debug 'Creating test user...'

user = User.find_or_initialize_by(email: 'test@example.com')
user.assign_attributes(
  name: 'Test User',
  password: 'password123',
  password_confirmation: 'password123'
)

if user.save
  Rails.logger.debug { "✓ User created: #{user.email}" }
  Rails.logger.debug { "  Name: #{user.name}" }
  Rails.logger.debug '  Password: password123'
else
  Rails.logger.debug { "✗ Error creating user: #{user.errors.full_messages.join(', ')}" }
end

Rails.logger.debug "\nSeeds completed!"
Rails.logger.debug "\nYou can now login with:"
Rails.logger.debug '  Email: test@example.com'
Rails.logger.debug '  Password: password123'
