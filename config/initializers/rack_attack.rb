# frozen_string_literal: true

class Rack::Attack
  throttle 'passwordless_verify/ip', limit: 5, period: 3.minutes do |req|
    if req.path_info == '/auth/passwordless/verify' && req.get?
      req.ip
    end
  end

  throttle 'passwordless_verify/token', limit: 5, period: 3.minutes do |req|
    if req.path_info == '/auth/passwordless/verify' && req.get?
      req.params['token'].presence
    end
  end

  throttle 'passwordless_create/ip', limit: 5, period: 3.minutes do |req|
    if req.path_info == '/auth/passwordless' && req.post?
      req.ip
    end
  end
end
