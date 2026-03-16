module RequestHelpers
  def json
    JSON.parse(response.body).with_indifferent_access
  end

  def auth_headers(user)
    service = Auth::AccessTokens::EncodeService.new(payload: { sub: user.id })
    service.call
    { "Authorization" => "Bearer #{service.output[:token]}" }
  end
end

RSpec.configure do |config|
  # Map spec/integration/auth/** to type: :request so request helpers are available
  config.define_derived_metadata(file_path: %r{spec/integration/}) do |metadata|
    metadata[:type] = :request
  end

  config.include RequestHelpers, type: :request
end
