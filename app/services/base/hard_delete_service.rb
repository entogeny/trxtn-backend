module Base
  class HardDeleteService < ApplicationService

    def call
      super do
        delete_record
      end
    end

    private

    def delete_record
      if record.destroy
        self.output = { record: record }
      else
        record.errors.full_messages.each { |message| add_error(message) }
      end
    end

    def record
      input[:record] or raise ServiceError.new("A record must be provided")
    end

  end
end
