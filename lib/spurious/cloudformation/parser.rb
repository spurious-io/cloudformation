require 'spurious/cloudformation/stackable'

module Spurious
  module Cloudformation
    class Parser < Stackable

      def parse(resources, params)
        data = {
          :dynamo => [],
          :s3 => [],
          :sqs => []
        }
        resources.each do |key, resource_data|
          if resource_data[:Type] == 'AWS::DynamoDB::Table'
            data[:dynamo] << parse_dynamo(key, resource_data[:Properties], params)
          end
        end
        data
      end

      def parse_dynamo(key, data, params)
        dynamo_hash = {
          :table_name => resource_name(key),
          :attribute_definitions => [],
          :key_schema => [],
          :provisioned_throughput => {
            :read_capacity_units => replace_param(data[:ProvisionedThroughput][:ReadCapacityUnits], params).to_i,
            :write_capacity_units => replace_param(data[:ProvisionedThroughput][:WriteCapacityUnits], params).to_i
          }
        }

        data[:KeySchema].each do |type, key_schema_data|
          object = {}
          key_schema_data.each do |key, value|
            object[underscore(key).to_sym] = value
            if key == :AttributeName
              dynamo_hash[:key_schema] << {
                :attribute_name => object[underscore(key).to_sym],
                :key_type => type.to_s.split(/(?=[A-Z])/)[0].upcase
              }
            end
          end
          dynamo_hash[:attribute_definitions] << object
        end
        dynamo_hash
      end

      private

      def replace_param(data, params)
        if data.is_a?(Hash) && !data[:Ref].nil?
          params[data[:Ref].to_sym]
        else
          data
        end
      end

      def underscore(item)
        item.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end

    end
  end
end
