module Events
  class IndexService < Base::IndexService

    private

    def model
      Event
    end

    def load_all
      # eager-load owner to avoid N+1 queries when serializing
      @records = base_scope.includes(:owner)
    end

    def order
      @records = @records.order(start_at: :asc)
    end

  end
end
