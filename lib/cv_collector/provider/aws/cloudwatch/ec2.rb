require 'time'
module CvCollector
  module Provider
    module Aws
      module CloudWatch
        class Ec2 < CloudWatch::Base
          MEASURE_NAMES = ["CPUUtilization", "NetworkIn", "NetworkOut"]
          RESOURCE_TYPE = 'compute'
          
          def fetch_data()
            super()

            REGIONS.each do |region|
              self.perform_action do
                ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
                instances = ec2.describe_instances
                cw = RightAws::AcwInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://monitoring.#{region}.amazonaws.com")
                instances.each do |instance|
                  MEASURE_NAMES.each do |measure_name|
                    metrics = cw.get_metric_statistics({:namespace => "AWS/EC2", 
                                                        :statistics => ["Average", "Sum", "Maximum", "Minimum"], 
                                                        :measure_name => measure_name, 
                                                        :period => PERIOD, 
                                                        :start_time => @start_time, 
                                                        :end_time => @end_time,
                                                        :dimentions => {"InstanceId" => instance[:aws_instance_id]},
                                                        })
                    metrics[:datapoints].each do |metric|
                      @data << parse_data(metric, instance[:aws_instance_id], RESOURCE_TYPE, measure_name)
                    end
                  end
                end
                instances
              end
              
            end
            
            return true
            
          end
          
        end
      end
    end
  end
end