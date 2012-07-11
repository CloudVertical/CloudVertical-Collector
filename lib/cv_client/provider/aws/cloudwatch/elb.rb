require 'time'
module CvClient
  module Provider
    module Aws
      module CloudWatch
        class Elb < CloudWatch::Base
          MEASURE_NAME = ['Latency', 'RequestCount']
          RESOURCE_TYPE = 'network'
          
          def fetch_data()
            super()

            REGIONS.each do |region|
              self.perform_action do
                elb = RightAws::ElbInterface.new(@access_key_id, @secret_access_key, :region => region)            
                balancers = elb.describe_load_balancers
                cw = RightAws::AcwInterface.new(@access_key_id, @secret_access_key, :region => region)
                balancers.each do |balancer|
                  MEASURE_NAME.each do |measure|
                    metrics = cw.get_metric_statistics({:namespace => 'AWS/ELB',
                                                        :statistics => ['Average', 'Maximum', 'Minimum', 'Sum'],
                                                        :measure_name => measure,
                                                        :period => PERIOD,
                                                        :start_time => @start_time, 
                                                        :end_time => @end_time,
                                                        :dimentions => {'LoadBalancerName' => balancer[:load_balancer_name]},
                                                        })
                    metrics[:datapoints].each do |metric|
                      @data << parse_data(metric, balancer[:load_balancer_name], RESOURCE_TYPE, measure)                    
                    end
                  end
                end
                balancers

              end
                       
            end
            
            return true
            
          end
          
        end
      end          
    end
  end
end
