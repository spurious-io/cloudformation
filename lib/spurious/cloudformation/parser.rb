module Spurious
  module Cloudformation
    class Parser

      def parse(resources, params)
        resources.each do |key, resource_data|
puts key

          if resource_data[:Type] == 'AWS::DynamoDB::Table'
            parse_dynamo(key, resource_data[:Properties])
          end


        end
      end

      def parse_dynamo(key, data)
puts data
        dynamo_hash = {
          :table_name => key,
          :attribute_definitions => [],
          :key_schema => [],
          :provisioned_throughput => {
            :read_capacity_units => data[:KeySchema][:ProvisionedThroughput][:ReadCapacityUnits],
            :write_capacity_units => data[:KeySchema][:ProvisionedThroughput][:WriteCapacityUnits]
          }
        }

        data[:KeySchema].each do |type, key_schema_data|
          object = {}
          key_schema_data.each do |key, value|
            object[underscore(key).to_sym] = value
          end
          dynamo_hash[:attribute_definitions] << object
          dynamo_hash[:key_schema] = {
            :attribute_name => object[underscore(key).to_sym],
            :key_type => key.split(/(?=[A-Z])/)[0].upcase
          }
        end

        puts dynamo_hash

      end

      private

      def underscore(item)
        item.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end

    end
  end
end
