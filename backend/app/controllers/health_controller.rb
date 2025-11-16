class HealthController < ApplicationController
  # GET /health
  def index
    render json: {
      status: 'ok',
      message: 'Veterinary Medical Report API is running',
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
  end
end
