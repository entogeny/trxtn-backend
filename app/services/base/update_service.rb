module Base
  class UpdateService < ApplicationService
    def call
      super do
        find_record
        assign_attributes
        save_record
      end
    end

    private

    attr_reader :record

    def assign_attributes
      # NOTE: This method is meant to be overridden by inheriting services to assign
      #   the record's attributes that should be updated.
      record.assign_attributes()
    end

    def find_record
      @record = model.find(input[:id])
    end

    def model
      # NOTE: Must be overwritten by inheriting services with the record's model class.
      #   e.g. If you were to do Example.find, it should return Example.
      raise MissingDefinitionError.new("#model must be implemented")
    end

    def save_record
      if record.save
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end
  end
end
