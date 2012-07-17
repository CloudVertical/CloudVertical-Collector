require 'time'
module CvCollector
  module Provider
    module Aws
      module CloudWatch
        class Rds < CloudWatch::Base
          MEASURE_NAME = ['CPUUtilization', 'FreeableMemory', 'FreeStorageSpace']
          RESOURCE_TYPE = 'compute'
          
      
          def fetch_data()
            super()

            REGIONS.each do |region|
              self.perform_action do
                rds = RightAws::RdsInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://rds.#{region}.amazonaws.com")
                instances = rds.describe_db_instances
                cw = RightAws::AcwInterface.new(@access_key_id, @secret_access_key, :endpoint_url => "https://monitoring.#{region}.amazonaws.com")
                instances.each do |instance|
                  MEASURE_NAME.each do |measure|
                    metrics = cw.get_metric_statistics({:namespace => "AWS/RDS", 
                                                        :statistics => ["Average", "Sum", "Maximum", "Minimum"], 
                                                        :measure_name => measure, 
                                                        :period => PERIOD, 
                                                        :start_time => @start_time, 
                                                        :end_time => @end_time,
                                                        :dimentions => {"DBInstanceIdentifier" => instance[:aws_id]},
                                                        })
                    metrics[:datapoints].each do |metric|
                      @data << parse_data(metric, instance[:aws_id], RESOURCE_TYPE, measure)                    
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