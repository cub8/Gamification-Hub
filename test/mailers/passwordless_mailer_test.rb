require "test_helper"

class PasswordlessMailerTest < ActionMailer::TestCase
  test "token_email" do
    mail = PasswordlessMailer.token_email
    assert_equal "Token email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
