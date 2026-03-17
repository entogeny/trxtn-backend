class Rack::Attack
  # Throttle login attempts by IP
  throttle("auth/login/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/auth/login" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by username (prevents distributed brute force)
  throttle("auth/login/username", limit: 5, period: 20.seconds) do |req|
    if req.path == "/auth/login" && req.post?
      req.params["username"]&.downcase&.presence
    end
  end

  # Throttle signup attempts by IP
  throttle("auth/signup/ip", limit: 3, period: 1.minute) do |req|
    if req.path == "/auth/signup" && req.post?
      req.ip
    end
  end

  # Return JSON for throttled requests
  self.throttled_responder = lambda do |req|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests. Please try again later." }.to_json ] ]
  end
end
