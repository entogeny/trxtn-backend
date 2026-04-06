module Events
  class FindService < Base::FindService

    private

    def model
      Event
    end

    def find_by_id
      # eager-load owner to avoid N+1 queries when serializing
      @record ||= base_scope.includes(:owner).find_by(id: input[:identifier])
    end

  end
end
