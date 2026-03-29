module Users
  class FindService < Base::FindService

    private

    def model
      User
    end

  end
end
