class MedicalRecordBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :original_filename, :pet_name, :species, :breed, :age,
         :owner_name, :diagnosis, :treatment, :notes, :created_at, :updated_at

  field :raw_text
  field :structured_data

  field :document_url do |record, _options|
    Rails.application.routes.url_helpers.rails_blob_url(record.document, only_path: true) if record.document.attached?
  end

  view :list do
    excludes :raw_text, :diagnosis, :treatment, :notes
  end
end
