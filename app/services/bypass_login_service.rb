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
    31d81e2138672bc0447da752b15e33e3bc6530810234cd0e00510894abce9e83
    098ae72bcffb09c8c9f7b210d1c8a98590e427237c0f3f8a1d4261a9c80d68b8
    793dca4cdc39b387ac40991306bc396ac4ef3b21191fca36993fbf97fe9ec78d
    c463e8d0501c777f1f6d5db007b5441d76629e4ad8cc629075a81cd1fc2c0fec
    170a3bb11c8aaf0cf179f735a98ecac77cb7447c8e30c08a402cfaf671d31e21
    f0c4a7f46a4403454631a57a09cd3c2b7695d6a3c698ddbe295b40a3759e4fad
    2e94efc57c3633564f87264be6f31f5e4f1738c50b23dabebc3594a63d8acbd5
  ].freeze

  def initialize(email:)
    @email = email
  end

  def can_bypass_login?
    email_hash = LoginToken.digest(@email)
    ALLOWED_ACCOUNTS_HASHES.include?(email_hash)
  end
end
