module AuthHelper
  def auth_headers(user)
    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      expires_in: 2.hours,
      scopes: ''
    )
    { 'Authorization' => "Bearer #{token.token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
