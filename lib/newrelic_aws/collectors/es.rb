module NewRelicAWS
  module Collectors
    class ES < Base
      def es_domains
        es = Aws::ElasticsearchService::Client.new(
          :access_key_id => @aws_access_key,
          :secret_access_key => @aws_secret_key,
          :region => @aws_region
        )
        es.list_domain_names.domain_names.map { |domain| domain.domain_name }
      end

      def metric_list
        [
          ["SearchableDocuments", "Average", "Count"],
          ["DeleteDocuments", "Average", "Count"],
          ["CPUUtilization", "Average", "Count"],
          ["MasterCPUUtilization", "Average", "Count"],
          ["FreeStorageSpace", "Minimum", "Count"],
          ["ReadLatency", "Average", "Count"],
          ["WriteLatency", "Average", "Count"],
          ["WriteThroughput", "Average", "Count"],
          ["ReadThroughput", "Average", "Count"],
          ["ReadIOPS", "Average", "Count"],
          ["WriteIOPS", "Average", "Count"]
        ]
      end

      def collect
        data_points = []
        es_domains.each do |domain|
          metric_list.each do |(metric_name, statistic, unit)|
            period = 300
            time_offset = 600 + @cloudwatch_delay
            data_point = get_data_point(
              :namespace   => "AWS/ES",
              :metric_name => metric_name,
              :statistic   => statistic,
              :unit        => unit,
              :dimension   => {
                :name  => "QueueName",
                :value => domain
              },
              :period => period,
              :start_time => (Time.now.utc - (time_offset + period)).iso8601,
              :end_time => (Time.now.utc - time_offset).iso8601
            )
            NewRelic::PlatformLogger.debug("metric_name: #{metric_name}, statistic: #{statistic}, unit: #{unit}, response: #{data_point.inspect}")
            unless data_point.nil?
              data_points << data_point
            end
          end
        end
        data_points
      end
    end
  end
end
