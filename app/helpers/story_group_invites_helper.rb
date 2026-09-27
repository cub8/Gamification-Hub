# frozen_string_literal: true

module StoryGroupInvitesHelper
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

  def invite_uses_label(invite)
    return "#{invite.uses}, bez limitu" if invite.max_uses.nil?

    "#{invite.uses} z #{invite.max_uses}"
  end

  def invite_expiry_label(invite)
    return 'Bez daty ważności' if invite.expires_at.nil?

    "#{invite.expire_time_condition ? 'Wygasa' : 'Wygasło'} #{gh_stamp(invite.expires_at)}"
  end

  def invite_stat_sentence(invite)
    expiry = if invite.expires_at.nil?
               'Bez daty ważności.'
             else
               "Wygasa #{gh_stamp(invite.expires_at)}."
             end

    "Użycia: #{invite_uses_label(invite)}. #{expiry}"
  end

  def invite_code_aria_label(invite)
    "Kod: #{invite.code.chars.join(' ')}"
  end

  def invite_option_label(invite)
    uses     = invite.max_uses.nil? ? 'bez limitu' : "#{invite.uses} z #{invite.max_uses}"
    validity = invite.expires_at.nil? ? 'bezterminowo' : "ważne do #{gh_stamp(invite.expires_at)}"

    "#{invite.code} – #{uses}, #{validity}"
  end
end
