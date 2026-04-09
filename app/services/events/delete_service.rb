module Events
  class DeleteService < Base::DeleteService

    private

    def model
      Event
    end

  end
end
