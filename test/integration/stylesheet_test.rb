# frozen_string_literal: true

require 'test_helper'

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

  test 'the wizard does not redefine a component owned elsewhere' do
    wizard = Rails.root.join('app/assets/stylesheets/components/wizard.css').read
    owned  = %w[gh-currency-balance-card gh-card gh-balance-button gh-price-badge gh-currency-token]

    owned.each do |klass|
      assert_no_match(/^\s*\.#{Regexp.escape(klass)}\s*[,{]/, wizard,
                      ".#{klass} belongs to another component; scope or rename the wizard's rule",)
    end
  end
end
