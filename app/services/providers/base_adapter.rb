# frozen_string_literal: true

module Providers
  # Each class inheriting from this base provider
  #   should implement their own build_params method.
  # If that's needed, you can also override constructor
  #   and params building method.
  class BaseAdapter
    attr_reader :auth, :usos_id, :university_number,
                :full_name, :university_name, :email, :role

    def initialize(auth)
      raise InvalidAuthError if auth.nil?

      @auth = auth
    end

    def user_params
      build_params unless @user_params

      @user_params ||= {
        email:             @email,
        usos_id:           @usos_id,
        university_name:   @university_name,
        university_number: @university_number,
        full_name:         @full_name,
        role:              @role,
      }
    end

    private

    def build_params
      raise NotImplementedError
    end
  end
end
