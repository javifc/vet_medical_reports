# frozen_string_literal: true

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  # For API-only applications, we skip this since we'll use password grant flow
  resource_owner_authenticator do
    # For API-only mode, we don't use session-based authentication
    # Authentication is handled via access tokens
    nil
  end

  # Authorization Code expiration time (in seconds).
  # If not set, defaults to 10 minutes.
  authorization_code_expires_in 10.minutes

  # Access token expiration time (default: 2 hours).
  access_token_expires_in 30.days

  # Assign custom TTL for access tokens.
  # Will be used instead of access_token_expires_in if defined.
  # In case the block returns `nil` value then access_token_expires_in will be used.
  # custom_access_token_expires_in do |context|
  #   context.scopes.include?("long_lived") ? 1.year : 2.hours
  # end

  # Use refresh token automatically.
  # The client credentials flow and the resource owner password credentials flow do not
  # support refresh tokens.
  use_refresh_token

  # Reuse access token for the same resource owner within an application (disabled by default).
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  reuse_access_token

  # Grant flows that you want to enable for your application.
  # Comment out or remove the flows you don't need:
  grant_flows %w[password] # Only password grant for API

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  skip_authorization do |resource_owner, client|
    true # Auto-approve all applications for API-only mode
  end

  # WWW-Authenticate Realm (default: "Doorkeeper").
  realm "Vet Medical Report API"

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # Callable objects such as proc, lambda, block or any object that responds to
  # #call can be used in order to allow conditional checks (to allow non-SSL
  # redirects to localhost for example).
  #
  force_ssl_in_redirect_uri !Rails.env.development?

  # Specify what redirect URI's you want to block during Application creation.
  # Any redirect URI is whitelisted by default.
  #
  # You can use this option in order to forbid URI's with 'javascript' scheme
  # for example.
  #
  # forbid_redirect_uri { |uri| uri.scheme.to_s.downcase == 'javascript' }

  # Allows to restrict only certain grant flows for Application.
  # By default, every grant flow is available.
  #
  # restrict_grant_flows_for_application do |application|
  #   ['password']
  # end

  # Specify what grant flows are enabled in case of an error on Authorization.
  # By default, all grant flows are available.
  #
  # handle_auth_errors :raise

  # Customize token_introspection response.
  # By default, the response includes only the `active` property.
  # custom_introspection_response do |token, context|
  #   {
  #     active: !token.expired?,
  #     scope: token.scopes.to_s,
  #     client_id: token.application_id,
  #     username: token.resource_owner_id,
  #   }
  # end

  # Specify the resource owner model.
  # For API-only applications, we'll use the User model
  resource_owner_from_credentials do |routes|
    user = User.find_by(email: params[:username])
    user if user&.authenticate(params[:password])
  end
end
