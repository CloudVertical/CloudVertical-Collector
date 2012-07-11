module CvCollector
  module Provider
    module Aws
      class Snapshot < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'snapshot'
        STATUSES = {'pending' => 'pending', 'completed' => 'completed', 'error' => 'error'}
        PATH = "/v01/generics.json"

        def fetch_data()
          REGIONS.each do |region|
            self.perform_action do
              ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
              snapshots = ec2.describe_snapshots(:Owner => 'self')
              snapshots.each do |snapshot|
                @data << parse_data(snapshot).merge('region' => region)
              end
              snapshots

            end
          end
          return true
          
        end
        
        def parse_data(snapshot)
          tags = snapshot[:tags].flatten.reject{|t| t=='Name' || t.empty?}
          return {'provider' => PROVIDER,
                  'generic_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'label' => snapshot[:tags] ? snapshot[:tags]['Name'] : '',            
                  'timestamp' => get_timestamp,
                  'reference_id' => snapshot[:aws_id], 
                  'status' => STATUSES[snapshot[:aws_status]],
                  'tags' => parse_tags(tags)}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end