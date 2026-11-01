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

  def invite_qr_svg(invite)
    RQRCode::QRCode.new(join_url(code: invite.code)).as_svg(
      viewbox:         true,
      module_size:     1,
      shape_rendering: 'crispEdges',
      svg_attributes:  { class: 'gh-print-qr', 'aria-hidden': 'true' },
    ).html_safe
  end

  def invite_uses_label(invite)
    return t('story_group_invites.helpers.uses_unlimited', uses: invite.uses) if invite.max_uses.nil?

    t('story_group_invites.helpers.uses_limited', uses: invite.uses, max: invite.max_uses)
  end

  def invite_expiry_label(invite)
    return t('story_group_invites.helpers.no_expiry') if invite.expires_at.nil?

    key = invite.expire_time_condition ? 'expires' : 'expired'
    t("story_group_invites.helpers.#{key}", date: gh_stamp(invite.expires_at))
  end

  def invite_stat_sentence(invite)
    expiry = if invite.expires_at.nil?
               t('story_group_invites.helpers.no_expiry')
             else
               t('story_group_invites.helpers.expires', date: gh_stamp(invite.expires_at))
             end

    t('story_group_invites.helpers.stat_sentence', uses: invite_uses_label(invite), expiry: expiry)
  end

  def invite_code_aria_label(invite)
    t('story_group_invites.helpers.code_label', code: invite.code.chars.join(' '))
  end

  def invite_option_label(invite)
    uses = if invite.max_uses.nil?
             t('story_group_invites.helpers.option_unlimited')
           else
             t('story_group_invites.helpers.uses_limited', uses: invite.uses, max: invite.max_uses)
           end
    validity = if invite.expires_at.nil?
                 t('story_group_invites.helpers.option_no_expiry')
               else
                 t('story_group_invites.helpers.option_valid_until', date: gh_stamp(invite.expires_at))
               end

    t('story_group_invites.helpers.option', code: invite.code, uses: uses, validity: validity)
  end

  # What invite_form_controller.ts needs to rebuild the form's summary line.
  def invite_form_wording
    t('story_group_invites.summary').merge(month_names: t('date.abbr_month_names'))
  end
end
