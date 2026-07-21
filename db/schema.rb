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

ActiveRecord::Schema[8.0].define(version: 2026_07_19_000000) do
  create_table "article_categories", force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.index ["article_id", "category_id"], name: "index_article_categories_on_article_id_and_category_id", unique: true
  end

  create_table "article_revisions", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "editor_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "status", null: false
    t.string "content_sha256", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "number"], name: "index_article_revisions_on_article_id_and_number", unique: true
    t.index ["article_id"], name: "index_article_revisions_on_article_id"
    t.index ["editor_id"], name: "index_article_revisions_on_editor_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "tag_id", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_on_article_id_and_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "slug"
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.text "moderation_reason"
    t.string "seo_title"
    t.string "seo_description"
    t.string "canonical_url"
    t.integer "lock_version", default: 0, null: false
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at"
  end

  create_table "audit_events", force: :cascade do |t|
    t.integer "actor_id"
    t.string "action", null: false
    t.string "subject_type", null: false
    t.integer "subject_id"
    t.json "metadata", default: {}, null: false
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["subject_type", "subject_id", "created_at"], name: "idx_audit_subject_time"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "media_assets", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "uploaded_by_id", null: false
    t.string "filename", null: false
    t.string "content_type", null: false
    t.integer "byte_size", null: false
    t.string "sha256", null: false
    t.string "storage_key", null: false
    t.string "alt_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_media_assets_on_article_id"
    t.index ["storage_key"], name: "index_media_assets_on_storage_key", unique: true
    t.index ["uploaded_by_id"], name: "index_media_assets_on_uploaded_by_id"
  end

  create_table "rate_limit_events", force: :cascade do |t|
    t.string "key_hash", null: false
    t.string "operation", null: false
    t.datetime "occurred_at", null: false
    t.index ["key_hash", "operation", "occurred_at"], name: "idx_rate_limits"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "password_digest"
    t.boolean "admin", default: false
    t.string "role", default: "author", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_signed_in_at"
  end

  add_foreign_key "article_revisions", "articles"
  add_foreign_key "article_revisions", "users", column: "editor_id"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "media_assets", "articles"
  add_foreign_key "media_assets", "users", column: "uploaded_by_id"
end
