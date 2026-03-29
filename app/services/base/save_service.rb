module Base
  class SaveService < ApplicationService

    def call
      super do
        if record.save
          self.output = { record: record }
        else
          record.errors.full_messages.each { |message| add_error(message) }
        end
      end
    end

    private

    def record
      input[:record]
    end

  end
end
