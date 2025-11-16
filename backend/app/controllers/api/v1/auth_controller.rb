class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:me, :logout]

  # POST /api/v1/auth/register
  def register
    user = User.new(user_params)

    if user.save
      # Create access token for the new user
      token = Doorkeeper::AccessToken.create!(
        resource_owner_id: user.id,
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        scopes: ''
      )

      render json: {
        user: user_response(user),
        token: token.token,
        token_type: 'Bearer',
        expires_in: token.expires_in
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/login
  # This is a custom login endpoint, but Doorkeeper's /oauth/token with password grant also works
  def login
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      # Create or reuse access token
      token = Doorkeeper::AccessToken.find_or_create_for(
        application: nil,
        resource_owner: user.id,
        scopes: '',
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: false
      )

      render json: {
        user: user_response(user),
        token: token.token,
        token_type: 'Bearer',
        expires_in: token.expires_in
      }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  # GET /api/v1/auth/me
  def me
    render json: { user: user_response(current_user) }
  end

  # DELETE /api/v1/auth/logout
  def logout
    doorkeeper_token&.revoke
    render json: { message: 'Logged out successfully' }
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at
    }
  end
end

