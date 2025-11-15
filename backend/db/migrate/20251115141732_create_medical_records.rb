class CreateMedicalRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_records do |t|
      t.string :status, null: false, default: 'pending'
      t.string :original_filename
      t.text :raw_text
      t.jsonb :structured_data, default: {}
      t.string :pet_name
      t.string :species
      t.string :breed
      t.string :age
      t.string :owner_name
      t.text :diagnosis
      t.text :treatment
      t.text :notes

      t.timestamps
    end

    add_index :medical_records, :status
    add_index :medical_records, :structured_data, using: :gin
  end
end
