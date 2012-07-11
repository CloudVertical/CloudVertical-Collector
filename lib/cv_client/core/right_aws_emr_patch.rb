module RightAws
  class EmrInterface
    class DescribeJobFlowsParser < RightAWSParser
      def tagstart(name, attributes)
        case full_tag_name
        when %r{/JobFlows/member$}
          @item = { :instance_groups => [],
                    :steps       => [],
                    :bootstrap_actions => [] }
        when %r{/BootstrapActionConfig$}
          @bootstrap_action = {}
        when %r{/InstanceGroups/member$}
          @instance_group = {}
        when %r{/Steps/member$}
          @step = { :args => [],
                    :properties => {},
                    :bootstrap_actions => []
                  }
        end
      end
    end
  end
end