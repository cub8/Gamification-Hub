# frozen_string_literal: true

require 'test_helper'

# The bundle's cascade is its import order (application.css says so in its
# own header). Everything lives in one `@layer components`, so two rules on
# a single class are decided by which file was imported last — not by which one
# looks more specific.
#
# This exists because that went wrong unnoticed: `.gh-form-shell--full` was written
# correctly, built correctly, and did nothing, because wizard.css was imported
# before the form.css rule it had to beat. Nothing rendered server-side can
# catch that, so the order is asserted directly.
class StylesheetTest < ActiveSupport::TestCase
  ENTRYPOINT = Rails.root.join('app/assets/stylesheets/application.css')

  def import_order
    ENTRYPOINT.read.scan(%r{@import "\./([\w/]+\.css)"}).flatten
  end

  test 'wizard.css is imported after the form shell it overrides' do
    order = import_order

    assert_operator order.index('components/wizard.css'), :>,
                    order.index('components/form.css'),
                    'wizard.css must load after form.css or .gh-form-shell--full loses to .gh-form-shell'
  end

  # The wizard's own preview borrowed this name once and would have restyled
  # the student's gold purse card the moment wizard.css moved last.
  test 'the wizard does not redefine a component owned elsewhere' do
    wizard = Rails.root.join('app/assets/stylesheets/components/wizard.css').read
    owned  = %w[gh-currency-balance-card gh-card gh-balance-button gh-price-badge gh-currency-token]

    owned.each do |klass|
      assert_no_match(/^\s*\.#{Regexp.escape(klass)}\s*[,{]/, wizard,
                      ".#{klass} belongs to another component; scope or rename the wizard's rule",)
    end
  end
end
