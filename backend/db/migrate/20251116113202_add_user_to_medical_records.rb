class AddUserToMedicalRecords < ActiveRecord::Migration[7.1]
  def up
    # Add user_id column as nullable first
    add_reference :medical_records, :user, null: true, foreign_key: true

    # Assign all existing medical records to the first user (test user)
    # Or you can delete them with: MedicalRecord.delete_all
    user = User.first
    if user
      MedicalRecord.where(user_id: nil).update_all(user_id: user.id)
    else
      # If no user exists, delete orphaned records
      MedicalRecord.where(user_id: nil).delete_all
    end

    # Make user_id not null
    change_column_null :medical_records, :user_id, false
  end

  def down
    remove_reference :medical_records, :user, foreign_key: true
  end
end
