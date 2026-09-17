# frozen_string_literal: true

# Opts a controller into the "Card Table" redesign.
#
#   class ItemsController < ApplicationController
#     include RedesignLayout
#   end
#
# Switches the layout and pulls in RedesignHelper, which the layout needs.
# The explicit `helper` call is required because this app sets
# `config.action_controller.include_all_helpers = false`.
#
# Set `@chrome = false` in an action for the focused, navigation-less shell
# (auth screens, wizards).
module RedesignLayout
  extend ActiveSupport::Concern

  included do
    layout 'redesign'
    helper RedesignHelper
  end
end
