# frozen_string_literal: true

require 'test_helper'

module Csv
  class GroupPresetTest < ActiveSupport::TestCase
    test 'defaults every collection to an empty array' do
      preset = GroupPreset.new

      assert_empty preset.ranks
      assert_empty preset.badges
      assert_empty preset.items
      assert_empty preset.templates
      assert_not preset.any?
      assert preset.none?
    end

    test 'any? is true once a single collection has rows' do
      preset = GroupPreset.new(ranks: [:not_really_a_rank])

      assert preset.any?
      assert_not preset.none?
    end
  end
end
