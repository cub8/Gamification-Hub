# frozen_string_literal: true

module Providers
  class DevelopmentAdapter < BaseAdapter
    class DevelopmentProviderOnProductionError < StandardError; end

    def initialize(auth)
      raise DevelopmentProviderOnProductionError if Rails.env.production?

      super
    end

    private

    def build_params
      @full_name = @auth[:full_name]
      @email = @auth[:email]
      @role = @auth[:role]
      @university_name = @auth[:university_name]
      @university_number = @auth[:university_number]
      @usos_id = nil
    end
  end
end
