# frozen_string_literal: true

module Fusuma
  module Plugin
    module Executors
      # Server executor plugin
      class ServerExecutor < Executor

        # executor properties on config.yml
        # @return [Array<Symbol>]
        def execute_keys
          [:server]
        end

        def config_param_types
          {
            pipe: [String],
          }
        end

        def initialize
          super()
          @pipe = File.open(config_params(:pipe), 'w')
        end

        def execute(event)
          command = search_command(event)

          MultiLogger.info(server: command, args: event.record.args)

          # File.write(@pipe, command.to_s + "\n")
          @pipe.write(command.to_s + "\n")
          @pipe.flush()
        rescue SystemCallError => e
          MultiLogger.error("#{event.record.index.keys}": e.message.to_s)
        end

        def executable?(event)
          event.tag.end_with?("_detector") &&
            event.record.type == :index &&
            search_command(event)
        end

        # @param event [Event]
        # @return [String]
        def search_command(event)
          command_index = Config::Index.new([*event.record.index.keys, :server])
          Config.instance.search(command_index)
        end

        # def enough_interval?(event)
        #   return true if event.record.index.keys.any? { |key| key.symbol == :end }
        #   env = event.record.args
        #     .deep_transform_keys(&:to_s)
        #     # .deep_transform_values { |v| (v * accel).to_s }
        #   puts '  enough_interval'
        #   direction = event.record.index.keys[2].symbol
        #   d = if [:right, :left].include?(direction)
        #     env['move_x'].abs()
        #   else
        #     nil
        #   end
        #   if d
        #     @distance ||= 0
        #     puts @distance
        #     @distance -= 0.07 * (0.01 + d - 0.1 * d**2)
        #     return @distance <= 0
        #   end
        #   return false if @wait_until && event.time < @wait_until
        #   true
        # end

        # def update_interval(event)
        #   direction = event.record.index.keys[2].symbol
        #   if [:right, :left].include?(direction)
        #     index = event.record.index
        #     config_value =
        #       Config.search(Config::Index.new([*index.keys, "interval"])) ||
        #       Config.search(Config::Index.new(["interval", Detectors::Detector.type(event.tag)]))
        #     @distance = config_value
        #   end
        #   super
        # end

      end
    end
  end
end
