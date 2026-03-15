module Auth
  module Errors
    class TokenExpired < StandardError; end
    class TokenInvalid < StandardError; end
    class TokenRevoked < StandardError; end
    class TokenNotFound < StandardError; end
  end
end
