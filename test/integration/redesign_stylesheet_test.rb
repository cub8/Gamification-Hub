# frozen_string_literal: true

require 'test_helper'

# The redesign bundle's cascade is its import order (redesign.css says so in
# its own header). Everything lives in one `@layer components`, so two rules on
# a single class are decided by which file was imported last — not by which one
# looks more specific.
#
# This exists because that went wrong unnoticed: `.gh-wiz--full` was written
# correctly, built correctly, and did nothing, because wizard.css was imported
# before the form.css rule it had to beat. Nothing rendered server-side can
# catch that, so the order is asserted directly.
class RedesignStylesheetTest < ActiveSupport::TestCase
  ENTRYPOINT = Rails.root.join('app/assets/stylesheets/redesign.css')

  def import_order
    ENTRYPOINT.read.scan(%r{@import "\./redesign/([\w/]+\.css)"}).flatten
  end

  test 'wizard.css is imported after the form shell it overrides' do
    order = import_order

    assert_operator order.index('components/wizard.css'), :>,
                    order.index('components/form.css'),
                    'wizard.css must load after form.css or .gh-wiz--full loses to .gh-wiz'
  end

  # The wizard's own preview borrowed this name once and would have restyled
  # the student's gold purse card the moment wizard.css moved last.
  test 'the wizard does not redefine a component owned elsewhere' do
    wizard = Rails.root.join('app/assets/stylesheets/redesign/components/wizard.css').read
    owned  = %w[gh-purse gh-card gh-bal gh-cost gh-tok]

    owned.each do |klass|
      assert_no_match(/^\s*\.#{Regexp.escape(klass)}\s*[,{]/, wizard,
                      ".#{klass} belongs to another component; scope or rename the wizard's rule",)
    end
  end
end
