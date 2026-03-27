module Base
  class DeleteService < ApplicationService
    def call
      super do
        find_record
        destroy_record
      end
    end

    private

    attr_reader :record

    def find_record
      find_service.call

      if !find_service.success?
        message = find_service.errors.map { |error| error[:message] }.join(", ")
        raise ServiceError.new(message)
      end

      @record = find_service.output[:record]
    end

    def find_service
      @find_service ||= "#{model.name.pluralize}::FindService".constantize.new(identifier: input[:id])
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
