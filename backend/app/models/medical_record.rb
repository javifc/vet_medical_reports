class MedicalRecord < ApplicationRecord
  belongs_to :user

  has_one_attached :document

  before_save :set_original_filename, if: -> { document.attached? && original_filename.blank? }

  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :document, presence: true, on: :create
  validate :document_format, if: -> { document.attached? }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  def initialize(attributes = {})
    super
    self.status ||= :created
  end

  def processed?
    completed? || failed?
  end

  def structured_data?
    structured_data.present? && structured_data.any?
  end

  private

  def set_original_filename
    self.original_filename = document.filename.to_s if document.attached?
  end

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
    return unless document.byte_size > 10.megabytes

    errors.add(:document, 'size must be less than 10MB')
  end
end
