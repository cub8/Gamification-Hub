# frozen_string_literal: true

# The latest e-mail sent to the given address, or nil if none was sent.
email = command_options['to']
mail = ActionMailer::Base.deliveries.reverse.find { it.to.include?(email) }

mail && { subject: mail.subject, text: (mail.text_part || mail).decoded }
