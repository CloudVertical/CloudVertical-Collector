require 'time'
module CvClient
  module Provider
    module Aws
      module CloudWatch
        class Ebs < CloudWatch::Base
          MEASURE_NAME = ['VolumeReadBytes', 'VolumeWriteBytes', 'VolumeReadOps', 'VolumeWriteOps']
          RESOURCE_TYPE = 'storage'
          
          def fetch_data()
            super()            
            REGIONS.each do |region|
              self.perform_action do
                ec2 = RightAws::Ec2.new(@access_key_id, @secret_access_key, :region => region)
                volumes = ec2.describe_volumes              
                cw = RightAws::AcwInterface.new(@access_key_id, @secret_access_key, :region => region)
                volumes.each do |volume|
                  MEASURE_NAME.each do |measure|
                    metrics = cw.get_metric_statistics({:namespace => 'AWS/EBS',
                                                        :statistics => ['Average', 'Maximum', 'Minimum', 'Sum'],
                                                        :measure_name => measure,
                                                        :period => PERIOD,
                                                        :start_time => @start_time, 
                                                        :end_time => @end_time,
                                                        :dimentions => {'VolumeId' => volume[:aws_id]},
                                                        })
                    metrics[:datapoints].each do |metric|
                      @data << parse_data(metric, volume[:aws_id], RESOURCE_TYPE, measure)                    
                    end
                  end
                end
                volumes
              end
            end
            return true
            
          end  
        end
      end          
    end
  end
end