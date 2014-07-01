require 'securerandom'

module Spurious
  module Cloudformation
    class Stackable

      attr_accessor :stack_name

      def initialize(stack_name)
        @stack_name = stack_name
      end

      protected

      def resource_name(identifier)
        "#{stack_name}-#{identifier}-#{SecureRandom.hex(6).upcase}"
      end

    end
  end
end
