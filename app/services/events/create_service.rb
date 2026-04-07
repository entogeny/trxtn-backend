module Events
  class CreateService < Base::CreateService

    private

    def assign_attributes
      record.assign_attributes(
        creator:     current_user,
        description: record_data[:description],
        end_at:      record_data[:end_at],
        name:        record_data[:name],
        owner:       current_user,
        start_at:    record_data[:start_at]
      )
    end

    def current_user
      input[:current_user]
    end

    def model
      Event
    end

    def record_data
      input[:record_data]
    end

    def save_record
      validate_future_start_at
      super
    end

    def validate_future_start_at
      if record.start_at.present? && record.start_at <= Time.current
        raise ServiceError.new("start_at must be in the future")
      end
    end

  end
end
