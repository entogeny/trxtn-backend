module Users
  class IndexService < Base::IndexService

    private

    def model
      User
    end

  end
end
