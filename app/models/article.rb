class Article < ActiveRecord::Base
  validates :title, presence: true, length: {minimum: 3, maximum: 50}
  validates :description, presence: true, length: {minimum: 10, maximum: 300}

  belongs_to :user

  has_many :article_categories
  has_many :categories, through: :article_categories
end