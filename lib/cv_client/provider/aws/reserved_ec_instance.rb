module CvClient
  module Provider
    module Aws
      class ReservedEcInstance < CvClient::Provider::Aws::Base
        
        RESOURCE_TYPE = 'reserved_ec_instance'
        STATUSES = { 'pending-payment' => 'pending-payment', 'active' => 'active', 'payment-failed' => 'payment-failed', 'retired' => 'retired' }
        PATH = "/v01/generics.json"

        def fetch_data()
          data = {}
          marked_as_reserved = JSON.parse(connection.get('/v01/computes/reserved?compute_type=ec_instance&format=json', @auth_token).body)
          marked_as_reserved.map!{|x| x.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}}
          
          REGIONS.each do |region|
            ec2 = RightAws::EcInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://elasticache.#{region}.amazonaws.com")
            reserved_instances = ec2.describe_reserved_cache_nodes
            _reserved_instances = []
            reserved_instances.each do |reserved_instance|
              @data << parse_data(reserved_instance, region)
              if reserved_instance[:state] == 'active'
                _reserved_instances << reserved_instance
              end
            end
            if _reserved_instances.size > 0
              # _instances = ec2.describe_instances
              data[region] = _reserved_instances#{:reserved => _reserved_instances, :instances => _instances}
            end
          end


          data.each do |region, _reserved_instances|
            _instances = nil
            _reserved_instances.each do |reserved|
              reserved[:instance_count].times do 
                instance_resources = CvClient::Provider::Aws::EcInstance::INSTANCE_TYPES[reserved[:instance_class]]
                if _inst = marked_as_reserved.find{|instance| instance[:region] == region && 
                                                              instance[:cpu] == instance_resources[:cpu] && 
                                                              instance[:status] == 'running' &&
                                                              instance[:ram] == instance_resources[:ram]                                                           
                                                              }
                  marked_as_reserved.delete(_inst)
                else
                  ec2 = RightAws::EcInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://elasticache.#{region}.amazonaws.com")
                  _instances ||= ec2.describe_cache_clusters
                  _inst = _instances.find{|instance| instance[:instance_class] == reserved[:instance_class] && 
                                                     instance[:status] == 'running'}
                  if _inst
                    _instances.delete(_inst)
                    connection.post({:auth_token => @auth_token, :data => [{:region => region, 
                                                :reference_id => _inst[:aws_id], 
                                                :provider => PROVIDER, 
                                                :tags => ['reserved'],
                                                :currency => 'USD',
                                                :interval => 3600,
                                                :cost => reserved[:usage_price],
                                                :compute_type => CvClient::Provider::Aws::EcInstance::RESOURCE_TYPE}]}, "/v01/computes.json")
                    
                  end
                end
              end
            end
          end
          marked_as_reserved.each do |res|
            connection.post({:auth_token => @auth_token, :data => [{:region => res[:region], 
                                        :reference_id => res[:reference_id], 
                                        :provider => PROVIDER, 
                                        :tags => [],
                                        :currency => nil,
                                        :interval => nil,
                                        :cost => nil,
                                        :compute_type => CvClient::Provider::Aws::EcInstance::RESOURCE_TYPE}]}, "/v01/computes.json")
          end
        {}  
          # 4 unsign tags
        rescue RightAws::AwsError => e
          p "CV_CLIENT ERROR: #{e}"  
          {}                  
        end
        
        def parse_data(reserved_instance, region)
          return {:provider => PROVIDER,
                  :generic_type => RESOURCE_TYPE,
                  :cloud_connection_id =>@cloud_connection_id,
                  :reference_id => reserved_instance[:aws_id],
                  :region => region,
                  :timestamp => get_timestamp,
                  :status => STATUSES[reserved_instance[:state]],
                  :cost => reserved_instance[:fixed_price],
                  :created_at => reserved_instance[:start_time],
                  :currency => 'USD',
                  :interval => reserved_instance[:duration],
                  :tags => parse_tags([])}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
          
        end

      end
    end
  end
end
