module Users
  class UpdateService < Base::UpdateService
    private

    def assign_attributes
      record.assign_attributes(
        username: input[:username]
      )
    end

    def model
      User
    end
  end
end
