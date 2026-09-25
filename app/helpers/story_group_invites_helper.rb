# frozen_string_literal: true

module StoryGroupInvitesHelper
  # Framework-neutral and deliberately untouched by any layout change. It
  # encodes join_url(code:), which JoinController#show serves as the QR
  # landing page — so the codes on every printout already point at the right
  # screen.
  def invite_qr_code(invite)
    url = join_url(code: invite.code)

    qrcode = RQRCode::QRCode.new(url)

    png = qrcode.as_png(
      bit_depth:      1,
      border_modules: 0,
      color_mode:     ChunkyPNG::COLOR_GRAYSCALE,
      color:          'black',
      fill:           'white',
      module_px_size: 6,
      size:           300,
    )

    image_tag(
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}",
      alt: '',
    )
  end

  # "3 z 30" / "8, bez limitu" (30-isg.js:23). The unlimited form keeps the
  # count first so the two read the same way down a column.
  def invite_uses_label(invite)
    return "#{invite.uses}, bez limitu" if invite.max_uses.nil?

    "#{invite.uses} z #{invite.max_uses}"
  end

  # Tense-aware: the same date is "Wygasa" while it is ahead and "Wygasło"
  # once it is behind (30-isg.js:26).
  def invite_expiry_label(invite)
    return 'Bez daty ważności' if invite.expires_at.nil?

    "#{invite.expire_time_condition ? 'Wygasa' : 'Wygasło'} #{gh_stamp(invite.expires_at)}"
  end

  # The stat line under the big code: "Użycia: 3 z 30. Wygasa 30.09, 23:59."
  def invite_stat_sentence(invite)
    expiry = if invite.expires_at.nil?
               'Bez daty ważności.'
             else
               "Wygasa #{gh_stamp(invite.expires_at)}."
             end

    "Użycia: #{invite_uses_label(invite)}. #{expiry}"
  end

  # Read out as characters, not as a word: "K 7 R B 2 Q" (30-isg.js:44).
  def invite_code_aria_label(invite)
    "Kod: #{invite.code.chars.join(' ')}"
  end

  # The compact line inside a <select> option on the quick-invite dialog:
  # "K7RB2Q – bez limitu, bezterminowo". Deliberately terser than
  # invite_uses_label/invite_expiry_label: an option has to read on one line,
  # and nobody is comparing use counts here.
  def invite_option_label(invite)
    uses     = invite.max_uses.nil? ? 'bez limitu' : "#{invite.uses} z #{invite.max_uses}"
    validity = invite.expires_at.nil? ? 'bezterminowo' : "ważne do #{gh_stamp(invite.expires_at)}"

    "#{invite.code} – #{uses}, #{validity}"
  end
end
