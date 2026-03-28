class User < ApplicationRecord
  include SoftDeletable

  has_secure_password

  has_many :refresh_tokens, dependent: :destroy

  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-z]+\z/, message: "can only contain lowercase letters" },
                       length: { minimum: 5, maximum: 30 }
end
