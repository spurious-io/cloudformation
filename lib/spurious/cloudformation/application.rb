require 'rack/response'
require 'rack/request'
require 'json'
require 'spurious/cloudformation/parser'

module Spurious
  module Cloudformation
    class Application

      def call(env)
        request = Rack::Request.new(env)
        query_params = request.POST

        template            = JSON.parse(query_params['TemplateBody'], :symbolize_names => true)
        override_params     = parameters_from(query_params)
        template_params     = params_from_template(template).merge(override_params)

        substitube_parameters(query_params['TemplateBody'], template_params)

        Spurious::Cloudformation::Parser.new.parse(template[:Resources], template_params)

        puts template

        response = Rack::Response.new(
          '',
          200,
          { "Content-Type" => "text/html" }
        ).finish

      end

      private

      def params_from_template(template)
        template[:Parameters].reduce({}) do |object, (key, value)|
          object.tap { |o| o[key] = value[:Default] }
        end
      end

      def parameters_from(params)
        params.reduce({}) do |object, (key, value)|
          object.tap do |o|
            o[value.to_sym] = params["Parameters.member.#{$1}.ParameterValue"] if key =~ /Parameters\.member\.([0-9]+)\.ParameterKey/
          end
        end
      end

      def substitube_parameters(template, params)
        params.each do |key, value|
          #{:Ref=>"SomeRef"}
          template.sub!("{:Ref=>\"#{key}\"}", value) if template =~ /{\s?:\s?Ref\s?\=\>\s?("|')#{key}("|')\s?}/
        end
      end

    end
  end
end
