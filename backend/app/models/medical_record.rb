class MedicalRecord < ApplicationRecord
  # Enums
  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # Validations
  validates :status, presence: true, inclusion: { in: statuses.keys }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  # Instance methods
  def processed?
    completed? || failed?
  end

  def has_structured_data?
    structured_data.present? && structured_data.any?
  end
end
