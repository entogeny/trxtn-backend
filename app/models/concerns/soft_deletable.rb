module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :not_soft_deleted, -> { where(deleted_at: nil) }
    scope :soft_deleted,     -> { where.not(deleted_at: nil) }
  end

  def soft_delete
    if soft_deleted?
      return false
    end

    update(deleted_at: Time.current)
  end

  def soft_undelete
    if !soft_deleted?
      return false
    end

    update(deleted_at: nil)
  end

  def soft_deleted?
    deleted_at.present?
  end

  def not_soft_deleted?
    !soft_deleted?
  end
end
