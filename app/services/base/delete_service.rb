module Base
  class DeleteService < ApplicationService
    def call
      super do
        destroy_record
      end
    end

    private

    def record
      if !input[:record] && !input[:id]
        raise ServiceError.new("A record or id must be provided")
      end

      @record ||= input[:record] || find_record
    end

    def find_record
      service = "#{model.name.pluralize}::FindService".constantize.new(identifier: input[:id])
      service.call

      if !service.success?
        message = service.errors.map { |error| error[:message] }.join(", ")
        raise ServiceError.new(message)
      end

      service.output[:record]
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   e.g. If you were to do Example.find, it should return Example.
      raise MissingDefinitionError.new("#model must be implemented")
    end

    def destroy_record
      case strategy
      when :soft then soft_delete_record
      when :hard then hard_delete_record
      else
        raise ServiceError.new("Unknown strategy: #{strategy}. Must be :soft or :hard")
      end
    end

    def strategy
      input.fetch(:strategy, :soft)
    end

    def soft_delete_record
      if !record.class.include?(SoftDeletable)
        raise ServiceError.new("#{record.class.name} does not support soft delete")
      end

      if record.soft_deleted?
        raise ServiceError.new("Record is already deleted")
      end

      if record.soft_delete
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end

    def hard_delete_record
      if record.destroy
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end
  end
end
