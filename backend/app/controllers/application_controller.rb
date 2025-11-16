class ApplicationController < ActionController::API
  include Doorkeeper::Helpers::Controller

  private

  # Returns the current authenticated user
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: doorkeeper_token&.resource_owner_id) if doorkeeper_token
  end

  # Requires authentication for endpoints
  def authenticate_user!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end
end
