# frozen_string_literal: true

module StoryGroupInvitesHelper
  def invite_qr_code(invite)
    url = join_url(code: invite.code)

    qrcode = RQRCode::QRCode.new(url)

    png = qrcode.as_png(
      bit_depth:      1,
      border_modules: 4,
      color_mode:     ChunkyPNG::COLOR_GRAYSCALE,
      color:          'black',
      fill:           'white',
      module_px_size: 6,
      size:           300,
    )

    image_tag(
      "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}",
      alt: 'Invite QR Code',
    )
  end
end
