require 'right_aws'
module RightAws

  class EcInterface < RightAwsBase
    
    include RightAwsBaseInterface

    API_VERSION      = "2012-03-09"
    DEFAULT_HOST     = 'elasticache.amazonaws.com'
    DEFAULT_PORT     = 443
    DEFAULT_PROTOCOL = 'https'
    DEFAULT_PATH     = '/'

    DEFAULT_INSTANCE_CLASS   =  'cache.m1.small'
    INSTANCE_CLASSES         = ['cache.m1.small', 'cache.m1.large', 'cache.m1.xlarge', 'cache.m2.2xlarge', 'cache.m2.2xlarge', 'cache.m2.4xlarge', 'cache.c1.xlarge']
    LICENSE_MODELS           = ['bring-your-own-license', 'license-included', 'general-public-license']

    @@bench = AwsBenchmarkingBlock.new
    def self.bench_xml
      @@bench.xml
    end
    def self.bench_service
      @@bench.service
    end

    def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, params={})
      init({ :name                => 'EC',
             :default_host        => params[:server] ? params[:server] : DEFAULT_HOST,
             :default_port        => ENV['EC_URL'] ? URI.parse(ENV['EC_URL']).port   : DEFAULT_PORT,
             :default_service     => ENV['EC_URL'] ? URI.parse(ENV['EC_URL']).path   : DEFAULT_PATH,
             :default_protocol    => ENV['EC_URL'] ? URI.parse(ENV['EC_URL']).scheme : DEFAULT_PROTOCOL,
             :default_api_version => ENV['EC_API_VERSION'] || API_VERSION },
           aws_access_key_id     || ENV['AWS_ACCESS_KEY_ID'], 
           aws_secret_access_key || ENV['AWS_SECRET_ACCESS_KEY'], 
           params)
    end

     def generate_request(action, params={})
       generate_request_impl(:get, action, params )
     end
      
     def request_info(request, parser, &block) # :nodoc:
       request_info_impl(:ec_connection, @@bench, request, parser, &block)
     end

    def describe_cache_clusters(*params, &block)
      item, params = AwsUtils::split_items_and_params(params)
      params = params.dup
      params['EcInstanceIdentifier'] = item.first unless item.right_blank?
      params['ShowCacheNodeInfo'] = true
      result = []
      incrementally_list_items('DescribeCacheClusters', DescribeCacheClustersParser, params) do |response|
        result += response[:ec_instances]
        block ? block.call(response) : true
      end
      result
    end
    
    def describe_reserved_cache_nodes(params={}, &block)
      params = params.dup
      result = []
      incrementally_list_items('DescribeReservedCacheNodes', DescribeReservedCacheNodesParser, params) do |response|
        result += response[:reserved_cache_nodes]
        block ? block.call(response) : true
      end
      result
    end

  end

  class DescribeCacheClustersParser < RightAWSParser
    def reset
      @result = { :ec_instances => [] }
    end

    def tagstart(name, attributes)
      case name
      when 'CacheCluster'                                then @item                       = { :cache_security_groups => [] }
      when 'CacheSecurityGroup'                          then @cache_security_group       = {}
      when 'CacheParameterGroup'                         then @cache_parameter_group      = {}
      when 'NotificationConfiguration'                   then @notification_configuration = {}
      when 'CacheNodes'                                  then @item[:cache_nodes]         = []
      when 'CacheNode'                                   then @cache_node                 = {}
      end
    end

    def tagend(name)
      case name
      when 'CacheNodeCreateTime'                         then @cache_node[:cache_node_create_time]                = @text
      when 'CacheNodeId'                                 then @cache_node[:cache_node_id]                         = @text
      when 'CacheNodeStatus'                             then @cache_node[:cache_node_status]                     = @text
      when 'Endpoint'                                    then @cache_node[:endpoint]                              = @text
      when 'ParameterGroupStatus'                        then @cache_node[:parameter_group_status]                = @text
      when 'CacheNode'                                   then @item[:cache_nodes]                                 << @cache_node 
      when 'CacheClusterId'                              then @item[:aws_id]                                      = @text
      when 'CacheClusterStatus'                          then @item[:cache_cluster_status]                        = @text
      when 'CacheNodeType'                               then @item[:cache_node_type]                             = @text
      when 'Engine'                                      then @item[:engine]                                      = @text
      when 'PendingModifiedValues'                       then @item[:pending_modified_values]                     = @text
      when 'PreferredAvailabilityZone'                   then @item[:preferred_availability_zone]                 = @text
      when 'CacheClusterCreateTime'                      then @item[:cache_cluster_create_time]                   = @text
      when 'EngineVersion'                               then @item[:engine_version]                              = @text
      when 'AutoMinorVersionUpgrade'                     then @item[:auto_minor_version_upgrade]                  = (@text == 'true')
      when 'PreferredMaintenanceWindow'                  then @item[:preferred_maintenance_window]                = @text
      when 'NumCacheNodes'                               then @item[:num_cache_nodes]                             = @text.to_i
      when 'CacheSecurityGroupName'                      then @cache_security_group[:cache_security_group_name]   = @text 
      when 'Status'                                      then @cache_security_group[:status]                      = @text
      when 'CacheSecurityGroup'                          then @item[:cache_security_groups]                       << @cache_security_group
      when 'TopicStatus'                                 then @notification_configuration[:topic_status]          = @text
      when 'TopicArn'                                    then @notification_configuration[:topic_arn]             = @text
      when 'NotificationConfiguration'                   then @item[:notification_configuration]                  = @notification_configuration
      when 'ParameterApplyStatus'                        then @cache_parameter_group[:parameter_apply_status]     = @text
      when 'CacheParameterGroupName'                     then @cache_parameter_group[:cache_parameter_group_name] = @text
      when 'CacheNodeIdsToReboot'                        then @cache_parameter_group[:cache_node_ids_to_reboot]   = @text
      when 'CacheParameterGroup', 'ParameterApplyStatus' then @item[:cache_parameter_group]                       = @cache_parameter_group
      when 'CacheCluster'                                then @result[:ec_instances]                              << @item
      end
    end
  end
  
  
  class DescribeReservedCacheNodesParser < RightAWSParser # :nodoc:
    def reset
      @result = { :reserved_cache_nodes => [] }
    end
    def tagstart(name, attributes)
      case name
      when 'ReservedCacheNode' then @item = {}
      end
    end
    def tagend(name)
      case name
      when 'CacheNodeCount'                then @result[:cache_node_count]  = @text.to_i
      when 'CacheNodeType'                 then @item[:cache_node_type]     = @text
      when 'Duration'                      then @item[:duration]            = @text.to_i
      when 'FixedPrice'                    then @item[:fixed_price]         = @text.to_f
      when 'UsagePrice'                    then @item[:usage_price]         = @text.to_f
      when 'OfferingType'                  then @item[:offering_type]       = @text 
      when 'ProductDescription'            then @item[:product_description] = @text
      when 'ReservedCacheNodesOfferingId ' then @item[:cache_nodes_offering_id]     = @text
      when 'ReservedCacheNodeId '          then @item[:aws_id]              = @text
      when 'State'                         then @item[:state]               = @text
      when 'StartTime'                     then @item[:start_time]          = @text
      end
    end
  end
  
end
