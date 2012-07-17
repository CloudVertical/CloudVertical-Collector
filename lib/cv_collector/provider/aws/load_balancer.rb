module CvCollector
  module Provider
    module Aws
      class LoadBalancer < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'load_balancer'
        PATH = "/v01/networks.json"

        def fetch_data()
          REGIONS.each do |region|
            self.perform_action do
              elb = RightAws::ElbInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://elasticloadbalancing.#{region}.amazonaws.com")
              balancers = elb.describe_load_balancers
              balancers.each do |balancer|
                @data << parse_data(balancer).merge('region' => region)
              end
              balancers
            end
          end
          return true
          
        end
        
        def parse_data(balancer)
          return {'provider' => PROVIDER,
                  'network_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'reference_id' => balancer[:load_balancer_name],
                  'timestamp' => get_timestamp,
                  'status' => 'running',
                  'created_at' => balancer[:created_time],
                  'tags' => parse_tags([])}
    
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end