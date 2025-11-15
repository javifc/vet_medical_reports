# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_15_141732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "medical_records", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.string "original_filename"
    t.text "raw_text"
    t.jsonb "structured_data", default: {}
    t.string "pet_name"
    t.string "species"
    t.string "breed"
    t.string "age"
    t.string "owner_name"
    t.text "diagnosis"
    t.text "treatment"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_medical_records_on_status"
    t.index ["structured_data"], name: "index_medical_records_on_structured_data", using: :gin
  end

end
