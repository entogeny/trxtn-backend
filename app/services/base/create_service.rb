module Base
  class CreateService < ApplicationService

    def call
      super do
        initialize_record
        assign_attributes
        validate
        save_record
      end
    end

    private

    attr_reader :record

    def assign_attributes
      # NOTE: This method is meant to be overridden by inheriting services to assign
      #   the record's attributes, unless you want to create a blank record and validations allow that.
      record.assign_attributes()
    end

    def validate
      # NOTE: Override in subclasses to add custom validation logic before saving.
      #   Raise a ServiceError to halt execution and surface an error message.
    end

    def initialize_record
      @record ||= model.new
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   e.g. If you were to do Example.new, it should return Example.
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
