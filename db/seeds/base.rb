# frozen_string_literal: true

module Seeds
  class Base
    class << self
      def call(...)
        new(...).call
      end
    end

    def call
      raise NotImplementedError
    end

    private

    def log_start(message)
      puts "Building #{message}"
    end

    def log_finish(message)
      puts " - Finished building #{message}"
    end
  end
end
