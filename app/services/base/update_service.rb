module Base
  class UpdateService < ApplicationService
    def call
      super do
        assign_attributes
        save_record
      end
    end

    private

    def record
      if !input[:record] && !input[:id]
        raise ServiceError.new("A record or id must be provided")
      end

      @record ||= input[:record] || find_record
    end

    def assign_attributes
      # NOTE: This method is meant to be overridden by inheriting services to assign
      #   the record's attributes that should be updated.
      record.assign_attributes()
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

    def save_record
      service = Base::SaveService.new(record: record)
      service.call

      if service.success?
        self.output = service.output
      else
        message = service.errors.map { |error| error[:message] }.join(", ")
        raise ServiceError.new(message)
      end
    end
  end
end
