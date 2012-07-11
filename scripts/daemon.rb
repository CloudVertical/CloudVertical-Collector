Signal.trap('CHLD', 'IGNORE')

lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)
require File.join(lib, 'cv_client')

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
    CvClient::Provider::Aws::Billing,
    CvClient::Provider::Aws::BillingProgramatic,
    CvClient::Provider::Aws::DynamoDB,                            
    CvClient::Provider::Aws::EC2Instance,
    CvClient::Provider::Aws::ReservedEC2Instance,
    CvClient::Provider::Aws::RdsInstance,
    CvClient::Provider::Aws::ReservedRdsInstance,
    CvClient::Provider::Aws::EcInstance,
    CvClient::Provider::Aws::ReservedEcInstance,
    CvClient::Provider::Aws::LoadBalancer,
    CvClient::Provider::Aws::BlockDevice,
    CvClient::Provider::Aws::Snapshot,
    CvClient::Provider::Aws::Emr,
    CvClient::Provider::Aws::CloudWatch::Ec2,
    CvClient::Provider::Aws::CloudWatch::Rds,
    CvClient::Provider::Aws::CloudWatch::Ec,
    CvClient::Provider::Aws::CloudWatch::Elb,
    CvClient::Provider::Aws::CloudWatch::Ebs
	]
  
  components.each do |c|
    obj = c.new()
    obj.fetch_data
    obj.send
  end

  CvClient::Provider::Aws::Base.save_sync
  
  sleep 60*60
end
