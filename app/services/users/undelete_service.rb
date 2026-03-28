module Users
  class UndeleteService < Base::UndeleteService
    private

    def model
      User
    end
  end
end
