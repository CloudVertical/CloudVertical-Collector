Signal.trap('CHLD', 'IGNORE')

lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)
require File.join(lib, 'cv_collector')

require 'yaml'
require 'faraday'
require 'faraday_middleware'
require 'yajl'
require 'time'
require 'mechanize'
require 'aws-sdk'
require 'right_aws'

CV_API_KEY = YAML::load(File.open("#{ENV["HOME"]}/.cvc/cv/credentials"))[:api_key]
AWS_CREDENTIALS = YAML::load(File.open("#{ENV["HOME"]}/.cvc/aws/credentials"))
API_URL = "https://resources.cloudvertical.com"
loop do

	components = [
    CvCollector::Provider::Aws::Billing,
    CvCollector::Provider::Aws::BillingProgramatic,
    CvCollector::Provider::Aws::DynamoDB,                            
    CvCollector::Provider::Aws::EC2Instance,
    CvCollector::Provider::Aws::ReservedEC2Instance,
    CvCollector::Provider::Aws::RdsInstance,
    CvCollector::Provider::Aws::ReservedRdsInstance,
    CvCollector::Provider::Aws::EcInstance,
    CvCollector::Provider::Aws::ReservedEcInstance,
    CvCollector::Provider::Aws::LoadBalancer,
    CvCollector::Provider::Aws::BlockDevice,
    CvCollector::Provider::Aws::Snapshot,
    CvCollector::Provider::Aws::Emr,
    CvCollector::Provider::Aws::CloudWatch::Ec2,
    CvCollector::Provider::Aws::CloudWatch::Rds,
    CvCollector::Provider::Aws::CloudWatch::Ec,
    CvCollector::Provider::Aws::CloudWatch::Elb,
    CvCollector::Provider::Aws::CloudWatch::Ebs
	]
  
  components.each do |c|
    obj = c.new()
    obj.fetch_data
    obj.send
  end

  CvCollector::Provider::Aws::Base.save_sync
  
  sleep 60*60
end
