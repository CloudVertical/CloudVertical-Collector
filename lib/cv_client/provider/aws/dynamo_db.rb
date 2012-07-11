module CvClient
  module Provider
    module Aws
      class DynamoDB < CvClient::Provider::Aws::Base
        
        RESOURCE_TYPE = 'dynamo_db'
        STATUSES = {}
        PATH = "/v01/storage.json"
        METRICS = ["ConsumedWriteCapacityUnits", "ConsumedReadCapacityUnits"]
        REGIONS = ["eu-west-1", "us-east-1", "ap-northeast-1", "us-west-2", "us-west-1", "ap-southeast-1"]
        
        def fetch_data()
          @now = Time.now.utc  
          @start_time, @end_time = (@now.beginning_of_day).iso8601, @now.end_of_day.iso8601
          
          REGIONS.each do |region|
            self.perform_action do
              dynamo_db = AWS::DynamoDB.new({:config => AWS::Core::Configuration.new, 
                                             :access_key_id => @access_key_id, 
                                             :secret_access_key =>  @secret_access_key,
                                             :dynamo_db_endpoint=>"dynamodb.#{region}.amazonaws.com"})
              table_names = dynamo_db.client.list_tables.data["TableNames"]
              table_names.each do |table_name|
                @data << parse_data({:table_name => table_name}).merge('region' => region)
                
                cw = RightAws::AcwInterface.new(@access_key_id, @secret_access_key, :region => region)
                METRICS.each do |metric|
                  capacity = cw.get_metric_statistics({:namespace => "AWS/DynamoDB", 
                                :statistics => ["Sum"], 
                                :measure_name => metric, 
                                :period => 24*3600, 
                                :start_time => @start_time, 
                                :end_time => @end_time,
                                :dimentions => {"TableName" => table_name},
                                })[:datapoints].inject(0){|x, y| x + y[:sum]}
                  @data << parse_child_data({:region => region, :table_name => table_name, :capacity => capacity, :metric => metric.gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase})
                end
          
              end
              table_names

            end
           
          end
          
          return true
          
        end
        
        def parse_data(table)
          return {'provider' => PROVIDER,
                  'storage_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'label' => table[:table_name],            
                  'reference_id' => table[:table_name],
                  'capacity' => 0,
                  'status' => 'running',
                  'timestamp' => get_timestamp,
                  'tags' => parse_tags([])}
        end
        
        def parse_child_data(child)
          prefix = get_timestamp.strftime("%Y-%m-%d")
          return {'provider' => PROVIDER,
                  'region' => child[:region],
                  'cloud_connection_id' => @cloud_connection_id,
                  'label' => '',            
                  'reference_id' => child[:metric]+"-"+prefix, 
                  'capacity' => child[:capacity],
                  'storage_type' => child[:metric],
                  'status' => 'running',
                  'timestamp' => get_timestamp,
                  'tags' => parse_tags([]),
                  'parent_id' => child[:table_name]}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end