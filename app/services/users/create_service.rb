module Users
  class CreateService < Base::CreateService
    private

    def assign_attributes
      record.assign_attributes(
        username: input[:username],
        password: input[:password],
        password_confirmation: input[:password_confirmation]
      )
    end

    def model
      User
    end
  end
end
