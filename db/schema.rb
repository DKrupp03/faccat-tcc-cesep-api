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

ActiveRecord::Schema[8.1].define(version: 2026_02_13_170630) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "anamneses", force: :cascade do |t|
    t.jsonb "anamnese_data", default: {}, null: false
    t.integer "anamnese_type", null: false
    t.datetime "created_at", null: false
    t.text "observations"
    t.integer "patient_id", null: false
    t.integer "therapist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["anamnese_data"], name: "index_anamneses_on_anamnese_data", using: :gin
    t.index ["anamnese_type"], name: "index_anamneses_on_anamnese_type"
    t.index ["patient_id"], name: "index_anamneses_on_patient_id"
    t.index ["therapist_id", "patient_id"], name: "index_anamnese_unique", unique: true
    t.index ["therapist_id"], name: "index_anamneses_on_therapist_id"
  end

  create_table "patient_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "observations", null: false
    t.integer "service_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_patient_progresses_on_service_id"
  end

  create_table "payments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expiration_date", null: false
    t.date "payment_date"
    t.integer "payment_method"
    t.integer "payment_status", default: 0, null: false
    t.integer "service_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.index ["service_id"], name: "index_payments_on_service_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "address"
    t.date "birth", null: false
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "crp"
    t.decimal "default_value", precision: 10, scale: 2
    t.integer "education_level"
    t.text "extra"
    t.integer "gender", null: false
    t.integer "marital_status"
    t.string "name", null: false
    t.string "occupation"
    t.jsonb "parent", default: {}
    t.string "phone"
    t.string "rg"
    t.integer "role", null: false
    t.integer "therapist_id"
    t.datetime "updated_at", null: false
    t.index ["therapist_id"], name: "index_profiles_on_therapist_id"
  end

  create_table "services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "datetime_end", null: false
    t.datetime "datetime_start", null: false
    t.text "observations"
    t.integer "patient_id", null: false
    t.integer "service_status", default: 0, null: false
    t.integer "service_type", null: false
    t.integer "therapist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_services_on_patient_id"
    t.index ["therapist_id"], name: "index_services_on_therapist_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.integer "profile_id", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["profile_id"], name: "index_users_on_profile_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "anamneses", "profiles", column: "patient_id"
  add_foreign_key "anamneses", "profiles", column: "therapist_id"
  add_foreign_key "patient_progresses", "services"
  add_foreign_key "payments", "services"
  add_foreign_key "profiles", "profiles", column: "therapist_id"
  add_foreign_key "services", "profiles", column: "patient_id"
  add_foreign_key "services", "profiles", column: "therapist_id"
  add_foreign_key "users", "profiles"
end
