# frozen_string_literal: true

# The text of the latest e-mail sent to the given address, or nil if none was sent.
mail = ActionMailer::Base.deliveries.reverse.find { it.to.include?(command_options['to']) }

mail && (mail.text_part || mail).decoded
