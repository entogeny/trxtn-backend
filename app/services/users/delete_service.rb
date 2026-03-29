module Users
  class DeleteService < Base::DeleteService

    private

    def model
      User
    end

  end
end
