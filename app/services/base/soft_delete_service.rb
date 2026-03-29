module Base
  class SoftDeleteService < ApplicationService
    def call
      super do
        validate_supports_soft_deletion
        validate_not_already_deleted
        delete_record
      end
    end

    private

    def delete_record
      if record.soft_delete
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end

    def record
      input[:record] or raise ServiceError.new("A record must be provided")
    end

    def validate_not_already_deleted
      if record.soft_deleted?
        raise ServiceError.new("Record is already deleted")
      end
    end

    def validate_supports_soft_deletion
      if !record.class.include?(SoftDeletable)
        raise ServiceError.new("#{record.class.name} does not support soft delete")
      end
    end
  end
end
