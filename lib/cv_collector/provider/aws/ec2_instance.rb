module CvCollector
  module Provider
    module Aws
      class EC2Instance < CvCollector::Provider::Aws::Base
        
        RESOURCE_TYPE = 'instance'
        STATUSES = {'pending' => 'running', 'running' => 'running', 'shutting-down' => 'stopped', 'terminated' => 'terminated', 'stopping' => 'stopped', 'stopped' => 'stopped'}
        PATH = "/v01/computes.json"
        
        def fetch_data()
          REGIONS.each do |region|
            
            self.perform_action do
              ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
              instances = ec2.describe_instances
              # instances images
              instance_images = {}
              if instances.size > 0
                instance_image_ids = instances.map{|instance| instance[:aws_image_id]}
                images = ec2.ec2_describe_images({'ImageId' => instance_image_ids})
                instance_images = Hash[images.map{|image| [image[:aws_id], image[:name]]}]
              end
              instances.each do |instance|
                @data << parse_data(instance, instance_images).merge('region' => region)
              end
              instances
            end
            
          end
          return true
        end
        
        def parse_data(instance, images = {})
          resources = INSTANCE_TYPES[instance[:aws_instance_type]]
          resource_type = RESOURCE_TYPE
          if instance[:instance_lifecycle]
            instance[:tags][:instance_lifecycle] = "spot"
            resource_type = "spot_instance"
          end
          tags = instance[:tags].flatten.reject{|t| t=='Name' || t.empty?}
          return {'provider' => PROVIDER,
                  'cloud_connection_id' => @cloud_connection_id,
                  'label' => instance[:tags] ? instance[:tags]['Name'] : '',
                  'compute_type' => resource_type,
                  'reference_id' => instance[:aws_instance_id], 
                  'platform' => platform(instance[:platform], images[instance[:aws_image_id]]),
                  'status' => STATUSES[instance[:aws_state]],
                  'hypervisor' => instance[:hypervisor],
                  'zone' => instance[:aws_availability_zone],
                  'architecture' => instance[:architecture],
                  'instance_type' => instance[:aws_instance_type],
                  'launch_time' => instance[:aws_launch_time],
                  'timestamp' => get_timestamp,
                  'tags' => parse_tags(tags)}.merge(resources)
        end
          
        def platform(platform, image_name)
          if platform && image_name && image_name.match(/windows.*sql.*standard/i)
            'windows_sql_standard'
          elsif platform && image_name && image_name.match(/windows.*sql.*express/i)
            'windows_sql_express'
          elsif platform
            'windows'
          elsif image_name && image_name.match(/sles/i)
            'sles'
          elsif image_name && image_name.match(/rhel/i)
            'rhel'
          else
            'linux'
          end
        end

        def send
          connection.post({:data => @data, :auth_token => @auth_token}, PATH)
        end

      end
    end
  end
end
