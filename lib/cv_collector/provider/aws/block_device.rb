module CvCollector
  module Provider
    module Aws
      class BlockDevice < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'block_device'
        STATUSES = {'creating' => 'available', 'available' => 'available', 'in-use' => 'in-use', 'deleting' => 'terminated', 'deleted' => 'terminated', 'error' => 'error'}
        PATH = "/v01/storage.json"

        def fetch_data()          
          REGIONS.each do |region|
            self.perform_action do
              ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
              volumes = ec2.describe_volumes
              volumes.each do |volume|
                @data << parse_data(volume).merge({'region' => region})
              end
              volumes
            end         
          end
          return true
        end
        
        def parse_data(volume)
          tags = volume[:tags].flatten.reject{|t| t=='Name' || t.empty?}
          return {'provider' => PROVIDER,
                  'storage_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'label' => volume[:tags] ? volume[:tags]['Name'] : '',            
                  'reference_id' => volume[:aws_id], 
                  'capacity' => volume[:aws_size].to_i * 1024,
                  'status' => STATUSES[volume[:aws_status]],
                  'zone' => volume[:zone],
                  'timestamp' => get_timestamp,
                  'tags' => parse_tags(tags)}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end