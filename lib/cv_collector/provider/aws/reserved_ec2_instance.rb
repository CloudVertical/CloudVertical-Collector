module CvCollector
  module Provider
    module Aws
      class ReservedEC2Instance < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'reserved_ec2_instance'
        STATUSES = { 'pending-payment' => 'pending-payment', 'active' => 'active', 'payment-failed' => 'payment-failed', 'retired' => 'retired' }
        PATH = "/v01/generics.json"

        def fetch_data()
          data = {}
          marked_as_reserved = JSON.parse(connection.get('/v01/computes/reserved?compute_type=instance&format=json', @auth_token).body)
          marked_as_reserved.map!{|x| x.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}}
          REGIONS.each do |region|
            ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
            reserved_instances = ec2.describe_reserved_instances
            _reserved_instances = []
            reserved_instances.each do |reserved_instance|
              @data << parse_data(reserved_instance, region)
              if reserved_instance[:aws_state] == 'active'
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
              reserved[:aws_instance_count].times do 
                instance_resources = INSTANCE_TYPES[reserved[:aws_instance_type]]
                if _inst = marked_as_reserved.find{|instance| instance[:zone] == reserved[:aws_availability_zone] && 
                                                              instance[:cpu] == instance_resources['cpu'] && 
                                                              instance[:status] == 'running' &&
                                                              instance[:ram] == instance_resources['ram'] && 
                                                              /#{instance[:platform]}/i.match(reserved[:aws_product_description])
                                                              }
                  marked_as_reserved.delete(_inst)
                else
                  ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
                  _instances ||= ec2.describe_instances
                  _inst = _instances.find{|instance| instance[:aws_instance_type] == reserved[:aws_instance_type] && 
                                                     instance[:aws_availability_zone] == reserved[:aws_availability_zone] &&
                                                     /#{instance[:platform] ? 'windows' : 'linux'}/i.match(reserved[:aws_product_description]) &&
                                                     instance[:aws_state] == 'running'}
                  if _inst
                    _instances.delete(_inst)
                    connection.post({:auth_token => @auth_token, :data => [{:region => region, 
                                                :reference_id => _inst[:aws_instance_id], 
                                                :provider => PROVIDER, 
                                                :tags => ['reserved'],
                                                :currency => 'USD',
                                                :interval => 3600,
                                                :cost => reserved[:aws_usage_price],
                                                :compute_type => CvCollector::Provider::Aws::EC2Instance::RESOURCE_TYPE}]}, "/v01/computes.json")
                    
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
                                        :compute_type => CvCollector::Provider::Aws::EC2Instance::RESOURCE_TYPE}]}, "/v01/computes.json")
          end
        {}  
          # 4 unsign tags
        rescue RightAws::AwsError => e
          p "cv_collector ERROR: #{e}"  
          {}                  
        end
        
        def parse_data(reserved_instance, region)
          tags = reserved_instance[:tags].flatten.reject{|t| t=='Name' || t.empty?}
          return {:provider => PROVIDER,
                  :generic_type => RESOURCE_TYPE,
                  :cloud_connection_id =>@cloud_connection_id,
                  :reference_id => reserved_instance[:aws_id],
                  :region => region,
                  :zone => reserved_instance[:aws_availability_zone],
                  :timestamp => get_timestamp,
                  :status => STATUSES[reserved_instance[:aws_state]],
                  :cost => reserved_instance[:aws_fixed_price],
                  :created_at => reserved_instance[:aws_start],
                  :currency => 'USD',
                  :interval => reserved_instance[:aws_duration],
                  :tags => parse_tags(tags)}
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
          
        end

      end
    end
  end
end
