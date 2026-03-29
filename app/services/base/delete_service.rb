module Base
  class DeleteService < ApplicationService
    def call
      super do
        delete_record
      end
    end

    private

    def delete_record
      service = strategy_service.new(record: record)
      service.call

      if service.success?
        self.output = service.output
      else
        service.errors.each { |error| add_error(error[:message]) }
      end
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

    def record
      if !input[:record] && !input[:id]
        raise ServiceError.new("A record or id must be provided")
      end

      @record ||= input[:record] || find_record
    end

    def strategy
      input.fetch(:strategy, :soft)
    end

    def strategy_service
      case strategy
      when :soft then Base::SoftDeleteService
      when :hard then Base::HardDeleteService
      else
        raise ServiceError.new("Unknown strategy: #{strategy}. Must be :soft or :hard")
      end
    end
  end
end
