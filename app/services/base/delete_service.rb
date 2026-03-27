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
      if record.destroy
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end
  end
end
