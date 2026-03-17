module Users
  class CreateService < ApplicationService
    def initialize(input = {})
      super
    end

    def call
      super do
        build_user
        save_user
      end
    end

    private

    attr_reader :user

    def build_user
      @user = User.new(
        username: input[:username],
        password: input[:password],
        password_confirmation: input[:password_confirmation]
      )
    end

    def save_user
      if user.save
        self.output = { user: user }
      else
        user.errors.full_messages.each { |message| add_error(message) }
      end
    end
  end
end
