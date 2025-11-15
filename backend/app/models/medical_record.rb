class MedicalRecord < ApplicationRecord
  # Active Storage
  has_one_attached :document

  # Enums
  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  # Validations
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validate :document_format, if: -> { document.attached? }

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

  private

  def document_format
    return unless document.attached?

    acceptable_types = [
      'application/pdf',
      'image/png',
      'image/jpeg',
      'image/jpg',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document', # .docx
      'application/msword' # .doc
    ]

    unless acceptable_types.include?(document.content_type)
      errors.add(:document, 'must be a PDF, image (PNG/JPG), or Word document')
    end

    # Size limit: 10MB
    if document.byte_size > 10.megabytes
      errors.add(:document, 'size must be less than 10MB')
    end
  end
end
