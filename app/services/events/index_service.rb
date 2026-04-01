module Events
  class IndexService < Base::IndexService

    private

    def model
      Event
    end

    def order
      @records = @records.order(start_at: :asc)
    end

  end
end
