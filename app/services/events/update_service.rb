module Events
  class UpdateService < Base::UpdateService

    private

    def assign_attributes
      record.assign_attributes(
        description: record_data[:description],
        end_at:      record_data[:end_at],
        name:        record_data[:name],
        owner_id:    record_data[:owner_id],
        start_at:    record_data[:start_at]
      )
    end

    def model
      Event
    end

    def record_data
      input[:record_data]
    end

    def validate
      validate_future_start_at
      validate_owner
    end

    def validate_future_start_at
      if !record_data[:start_at].present?
        return
      end

      if record.start_at.present? && record.start_at <= Time.current
        raise ServiceError.new("start_at must be in the future")
      end
    end

    def validate_owner
      if !record.owner_id_changed? || record.owner_id.nil?
        return
      end

      if !User.exists?(record.owner_id)
        raise ServiceError.new("Owner not found")
      end
    end

  end
end
