module Roadworker
  class DSL
    class Converter
      class << self
        def convert(exported)
          self.new(exported).convert
        end
      end # of class method

      def initialize(exported)
        @health_checks = exported[:health_checks]
        @hosted_zones = exported[:hosted_zones]
      end

      def convert
        @hosted_zones.map {|i| output_zone(i) }.join("\n")
      end

      private

        def output_rrset(recrod)
          name = recrod.delete(:name).inspect
          type = recrod.delete(:type).inspect

          attrs = recrod.map {|key, value|
            case key
            when :resource_records
              if value.empty?
                nil
              else
                value = value.map {|i| i.inspect }.join(",\n      ")
                "#{key}(\n      #{value}\n    )"
              end
            when :health_check_id
              config = HealthCheck.config_to_hash(@health_checks[value])
              hc_args = config[:url].sub(/\A(https?)_str_match:/) { $1 + ':' }.inspect

              [:host, :search_string, :request_interval, :failure_threshold].each do |key|
                if config[key]
                  hc_args << ", :#{key} => #{config[key].inspect}"
                end
              end

              "health_check #{hc_args}"
            else
              "#{key} #{value.inspect}"
            end
          }.select {|i| i }.join("\n    ")

          return(<<-EOS)
  rrset #{name}, #{type} do
    #{attrs}
  end
          EOS
        end

        def output_zone(zone)
          name = zone[:name].inspect
          rrsets = zone[:rrsets]

          return(<<-EOS)
hosted_zone #{name} do
#{rrsets.map {|i| output_rrset(i) }.join("\n").chomp}
end
          EOS
        end

    end # Converter
  end # DSL
end # Roadworker
