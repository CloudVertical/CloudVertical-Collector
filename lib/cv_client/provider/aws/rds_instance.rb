module CvClient
  module Provider
    module Aws
      class RdsInstance < CvClient::Provider::Aws::Base
        
        RESOURCE_TYPE = 'rds_instance'
        # API not included info about statuses
        STATUSES = {'creating' => 'running', 'rebooting' => 'running', 'available' => 'running', 'terminated' => 'terminated'}
        PATH = "/v01/computes.json"
        INSTANCE_TYPES = {
                          "db.t1.micro"   => {'cpu' => 1,   'ram' => 0.63},
                          "db.m1.small"   => {'cpu' => 1,   'ram' => 1.7},
                          "db.m1.large"   => {'cpu' => 4,   'ram' => 7.5},
                          "db.m1.xlarge"  => {'cpu' => 8,   'ram' => 15},
                          "db.m2.xlarge"  => {'cpu' => 6.5, 'ram' => 17.1},
                          "db.m2.2xlarge" => {'cpu' => 13,  'ram' => 34},
                          "db.m2.4xlarge" => {'cpu' => 26,  'ram' => 68}
                          }

        def fetch_data()
          REGIONS.each do |region|
            self.perform_action do
              rds = RightAws::RdsInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://rds.#{region}.amazonaws.com")
              instances = rds.describe_db_instances
              instances.each do |instance|
                @data << parse_data(instance).merge('region' => region)
              end
              instances
            end

          end
          return true
          
        end
        
        def parse_data(instance)
          storage = instance[:allocated_storage]
          resources = INSTANCE_TYPES[instance[:instance_class]].merge(:storage => storage)
          return {'provider' => PROVIDER,
                  'compute_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'reference_id' => instance[:aws_id],
                  'platform' => (instance[:engine] + '/' + instance[:license_model].gsub('-', '_') + (instance[:multi_az] == true ? '/multi_az' : '')),
                  'status' => STATUSES[instance[:status]],
                  'launch_time' => instance[:create_time],
                  'timestamp' => get_timestamp,
                  'zone' => instance[:availability_zone],
                  'instance_type' => instance[:instance_class],
                  'tags' => parse_tags([])}.merge(resources)
    
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end