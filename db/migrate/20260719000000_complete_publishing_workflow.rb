class CompletePublishingWorkflow < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :string, null: false, default: "author"
    add_column :users, :active, :boolean, null: false, default: true
    add_column :users, :last_signed_in_at, :datetime

    add_column :articles, :slug, :string
    add_column :articles, :status, :string, null: false, default: "draft"
    add_column :articles, :published_at, :datetime
    add_column :articles, :moderation_reason, :text
    add_column :articles, :seo_title, :string
    add_column :articles, :seo_description, :string
    add_column :articles, :canonical_url, :string
    add_column :articles, :lock_version, :integer, null: false, default: 0
    add_index :articles, :slug, unique: true
    add_index :articles, [:status, :published_at]

    create_table :article_revisions do |t|
      t.references :article, null: false, foreign_key: true
      t.references :editor, null: false, foreign_key: { to_table: :users }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :status, null: false
      t.string :content_sha256, null: false
      t.timestamps null: false
    end
    add_index :article_revisions, [:article_id, :number], unique: true

    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end
    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true

    create_table :article_tags do |t|
      t.references :article, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end
    add_index :article_tags, [:article_id, :tag_id], unique: true

    create_table :media_assets do |t|
      t.references :article, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false
      t.string :sha256, null: false
      t.string :storage_key, null: false
      t.string :alt_text, null: false
      t.timestamps null: false
    end
    add_index :media_assets, :storage_key, unique: true

    create_table :audit_events do |t|
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :subject_type, null: false
      t.integer :subject_id
      t.json :metadata, null: false, default: {}
      t.string :request_id
      t.timestamps null: false
    end
    add_index :audit_events, [:subject_type, :subject_id, :created_at], name: "idx_audit_subject_time"

    create_table :rate_limit_events do |t|
      t.string :key_hash, null: false
      t.string :operation, null: false
      t.datetime :occurred_at, null: false
    end
    add_index :rate_limit_events, [:key_hash, :operation, :occurred_at], name: "idx_rate_limits"

    add_index :article_categories, [:article_id, :category_id], unique: true
  end
end
