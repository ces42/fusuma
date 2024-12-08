# frozen_string_literal: true

require_relative "../base"

module Fusuma
  module Plugin
    # executor class
    module Executors
      # Inherite this base
      class Executor < Base
        BASE_ONESHOT_INTERVAL = 0.3
        BASE_REPEAT_INTERVAL = 0.1

        # Executor parameter on config.yml
        # @return [Array<Symbol>]
        def execute_keys
          # [name.split('Executors::').last.underscore.gsub('_executor', '').to_sym]
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # check executable
        # @param _event [Events::Event]
        # @return [TrueClass, FalseClass]
        def executable?(_event)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end

        # @param event [Events::Event]
        # @return [TrueClass, FalseClass]
        def enough_interval?(event)
          return true if event.record.index.keys.any? { |key| key.symbol == :end }

          return false if @wait_until && event.time < @wait_until

          true
        end

        def update_interval(event)
          @wait_until = event.time + interval(event).to_f
        end

        def enough_distance?(event)
          puts @direction
          if @direction.nil? || @direction == event.record.index.keys[2].symbol then
            @distance += event.record.args.
          else
            @direction = nil
          end
          false
        end

        def update_distance(event)
          @direction = event.record.index.keys[2].symbol
        end

        def interval(event)
          @interval_time ||= {}
          index = event.record.index
          @interval_time[index.cache_key] ||= begin
            config_value =
              Config.search(Config::Index.new([*index.keys, "interval"])) ||
              Config.search(Config::Index.new(["interval", Detectors::Detector.type(event.tag)]))
            if event.record.trigger == :oneshot
              (config_value || 1) * BASE_ONESHOT_INTERVAL
            else
              (config_value || 1) * BASE_REPEAT_INTERVAL
            end
          end
        end

        # execute something
        # @param _event [Event]
        # @return [nil]
        def execute(_event)
          raise NotImplementedError, "override #{self.class.name}##{__method__}"
        end
      end
    end
  end
end
