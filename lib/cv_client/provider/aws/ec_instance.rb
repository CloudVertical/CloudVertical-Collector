module CvClient
  module Provider
    module Aws
      class EcInstance < CvClient::Provider::Aws::Base
        
        RESOURCE_TYPE = 'ec_instance'
        STATUSES = {'creating' => 'running', 'deleting' => 'terminated', 'available' => 'running'}
        # TODO: find all node statuses
        NODE_STATUSES = {'creating' => 'running', 'deleting' => 'terminated', 'available' => 'running'}
        PATH = "/v01/computes.json"
        INSTANCE_TYPES = {"cache.m1.small"   => {'cpu' => 1,   'ram' => 1.3},
                          'cache.m1.large'   => {'cpu' => 4,   'ram' => 7.1},
                          "cache.m1.xlarge"  => {'cpu' => 8,   'ram' => 14.6},
                          "cache.m2.xlarge"  => {'cpu' => 6.5, 'ram' => 16.7},
                          "cache.m2.2xlarge" => {'cpu' => 13,  'ram' => 33.8},
                          "cache.m2.4xlarge" => {'cpu' => 26,  'ram' => 68},
                          "cache.c1.xlarge" => {'cpu' => 26,  'ram' => 6.6},                          
                          }

        def fetch_data()
          REGIONS.each do |region|
            self.perform_action do
              ec = RightAws::EcInterface.new(@access_key_id, @secret_access_key, :server => "elasticache.#{region}.amazonaws.com")
              instances = ec.describe_cache_clusters
              instances.each do |instance|
                @data << parse_data(instance).merge('region' => region)
                instance[:cache_nodes].each do |node|
                  @data << parse_node_data(instance, node).merge('region' => region)
                end if instance[:cache_nodes].size > 0
              end
              instances
            end
          
          end
          return true
        end
        
        def parse_node_data(instance, node)
          cpu = INSTANCE_TYPES[instance[:cache_node_type]]['cpu']
          ram = INSTANCE_TYPES[instance[:cache_node_type]]['ram']
          resources = {'cpu' => cpu, 'ram' => ram}
          return {'provider' => PROVIDER,
                  'compute_type' => RESOURCE_TYPE,
                  'cloud_connection_id' => @cloud_connection_id,
                  'parent_id' => instance[:aws_id],
                  'reference_id' => node[:cache_node_id],
                  'platform' => 'linux',
                  'timestamp' => get_timestamp,
                  'status' => NODE_STATUSES[node[:cache_node_status]],
                  'instance_type' => instance[:cache_node_type],                  
                  'launch_time' => node[:cache_node_create_time],
                  'tags' => parse_tags([MAP_INSTANCE_TYPES[instance[:cache_node_type]]])}.merge(resources)          
        end
        
        def parse_data(instance)
          num_cache_nodes = instance[:num_cache_nodes]
          cpu_sum = INSTANCE_TYPES[instance[:cache_node_type]]['cpu'] * num_cache_nodes
          ram_sum = INSTANCE_TYPES[instance[:cache_node_type]]['ram'] * num_cache_nodes
          resources = {'cpu' => cpu_sum, 'ram' => ram_sum}
          return {'provider' => PROVIDER,
                  'compute_type' => 'cache_cluster',
                  'cloud_connection_id' => @cloud_connection_id,
                  'reference_id' => instance[:aws_id], 
                  'platform' => 'linux',
                  'status' => STATUSES[instance[:cache_cluster_status]],
                  'timestamp' => get_timestamp,
                  'instance_type' => instance[:cache_node_type],
                  'launch_time' => instance[:cache_cluster_create_time],
                  'tags' => parse_tags([])}.merge(resources)
    
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end
