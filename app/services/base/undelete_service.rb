module Base
  class UndeleteService < ApplicationService

    def call
      super do
        validate
        undelete_record
      end
    end

    private

    def find_record
      # Searches all records, including soft-deleted ones — this is intentional.
      # UndeleteService must be able to find records that FindService explicitly excludes.
      found = model.find_by(id: input[:id])
      if found.nil?
        raise ServiceError.new("Unable to find record by identifier: #{input[:id]}")
      end
      found
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   e.g. If you were to do Example.find, it should return Example.
      raise MissingDefinitionError.new("#model must be implemented")
    end

    def record
      if !input[:record] && !input[:id]
        raise ServiceError.new("A record or id must be provided")
      end

      @record ||= input[:record] || find_record
    end

    def undelete_record
      if record.soft_undelete
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end

    def validate
      validate_supports_soft_deletion
      validate_was_soft_deleted
    end

    def validate_supports_soft_deletion
      if !record.class.include?(SoftDeletable)
        raise ServiceError.new("#{record.class.name} does not support soft delete")
      end
    end

    def validate_was_soft_deleted
      if !record.soft_deleted?
        raise ServiceError.new("Record is not deleted")
      end
    end

  end
end
