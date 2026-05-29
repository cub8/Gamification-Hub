# frozen_string_literal: true

# Temporary service existing for testing purposes
class BypassLoginService
  ALLOWED_ACCOUNTS_HASHES = %w[
    f34edb60fe96bf7c5257e3a6f91fcd8ef800919bb0b5bf2567e44d3e56aa8adf
    6645d198a00c98546eadf64131948608708ffb8d5b6295adfded5aa7b1f39b5c
    121feb6ebafd1472432b61cc6c6509be65a5d17e1013a2516004e2c1d5130812
    4ded97020583d0d0f8d0c2a286bd0334820becb4963772fce6e9b985aa1ecd71
    0b0489a39a272d165ea1939691313bdf087628abd0c164189a45e2568df0df0e
    aa6cd9df62bcff8b9317aec8ecfdaa882b20735b227e3598c6d7f2ed14405c55
    20446f49263d51f94b3a1e609fb1771e9f570e810084a029be970ef8e26710b2
  ].freeze

  def initialize(email:)
    @email = email
  end

  def can_bypass_login?
    email_hash = LoginToken.digest(@email)
    ALLOWED_ACCOUNTS_HASHES.include?(email_hash)
  end
end
