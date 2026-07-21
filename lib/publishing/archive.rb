require "json"

module Publishing
  class Archive
    VERSION = 1

    def self.export
      {
        format: "alpha-blog", version: VERSION, exported_at: Time.current.iso8601,
        users: User.order(:id).map { |u| u.attributes.slice("username", "email", "role", "active") },
        categories: Category.order(:id).pluck(:name),
        tags: Tag.order(:id).pluck(:name),
        articles: Article.includes(:categories, :tags, :article_revisions).order(:id).map do |article|
          article.attributes.slice("title", "description", "slug", "status", "published_at",
                                   "seo_title", "seo_description", "canonical_url").merge(
            "author_email" => article.user.email,
            "categories" => article.categories.map(&:name),
            "tags" => article.tags.map(&:name),
            "revisions" => article.article_revisions.order(:number).map { |r| r.attributes.except("id", "article_id", "editor_id") }
          )
        end
      }
    end

    def self.import!(payload, actor:)
      data = payload.is_a?(String) ? JSON.parse(payload) : payload
      raise ArgumentError, "unsupported archive" unless data["format"] == "alpha-blog" && data["version"] == VERSION
      Article.transaction do
        Array(data["articles"]).each do |row|
          author = User.find_by!(email: row.fetch("author_email"))
          article = author.articles.find_or_initialize_by(slug: row.fetch("slug"))
          article.assign_attributes(row.slice("title", "description", "status", "published_at", "seo_title", "seo_description", "canonical_url"))
          article.save!
          article.categories = Array(row["categories"]).map { |name| Category.find_or_create_by!(name: name) }
          article.tags = Array(row["tags"]).map { |name| Tag.find_or_create_by!(name: name) }
          AuditEvent.record!(actor: actor, action: "article.imported", subject: article)
        end
      end
    end
  end
end
