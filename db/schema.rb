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

ActiveRecord::Schema[8.1].define(version: 2026_01_21_211631) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "anamneses", force: :cascade do |t|
    t.boolean "alcoholic", default: false
    t.datetime "created_at", null: false
    t.text "disease_history"
    t.string "emergency_contact"
    t.boolean "healthy_eating", default: false
    t.text "initial_complaint"
    t.text "medications"
    t.text "observations"
    t.integer "patient_id"
    t.boolean "physical_activity", default: false
    t.boolean "smoking", default: false
    t.text "symptom_time"
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_anamneses_on_patient_id"
  end

  create_table "users", force: :cascade do |t|
    t.date "birth", null: false
    t.string "cpf", null: false
    t.datetime "created_at", null: false
    t.string "crp"
    t.string "email", null: false
    t.text "extra"
    t.integer "gender", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "rg"
    t.datetime "updated_at", null: false
    t.integer "user_type", null: false
  end

  add_foreign_key "anamneses", "users", column: "patient_id"
end
