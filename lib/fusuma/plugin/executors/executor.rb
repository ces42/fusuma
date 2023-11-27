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
        BASE_DISTANCE = 10

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
          index = event.record.index
          if index.keys.any? { |key| key.symbol == :begin } and index.keys.any? { |key| key.symbol == :swipe} then
            mult = 5
          else
            mult = 1
          end
          @wait_until = event.time + interval(event).to_f * mult
          true
        end

        def enough_distance?(event)
          # if event.record.index.keys.any? { |key| key.symbol == :end } then
          # @direction = nil
          # @distance = 0
          # return true
          # end

          return true unless event.record.index.keys.any?{ |key| key.symbol == :swipe }

          direction = event.record.index.keys.find{ |key| [:left, :right, :up, :down].include?(key.symbol) }
          return true if direction.nil?
          direction = direction.symbol

          if @direction != direction then
            @direction = direction
            # @distance = 0 if @distance.nil? or @distance < 10000
            @distance = 0
          end

          # puts "  direction: #{direction}"
          if [:right, :left].include?(@direction) then
            @distance += event.record.args[:move_x].abs() + 0.1
          elsif [:up, :down].include?(direction) then
            @distance += event.record.args[:move_y].abs() + 0.1
          else
            @direction = nil
            return false
          end
          # puts "  distance: #{@distance}"
          @distance > distance(event)
        end

        def update_distance(event)
          # if event.record.index.keys.any? { |key| key.symbol == :begin } then
          #   @distance = distance(event)/2
          #   puts "-----------------"
          #   puts "  -- #{@distance}"
          # else
          if event.record.index.keys.any? { |key| key.symbol == :swipe} then
            @distance -= distance(event)
          end
          # end
          true
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

        def distance(event)
          @distance_cache ||= {}
          index = event.record.index
          @distance_cache[index.cache_key] ||= begin
            # keys_specific = Config::Index.new [*index.keys, "distance"]
            # keys_global = Config::Index.new ["distance", type]
            # config_value = Config.search(keys_specific) ||
            # Config.search(keys_global) || 0
            config_value =
              Config.search(Config::Index.new([*index.keys, "distance"])) ||
              Config.search(Config::Index.new(["distance", Detectors::Detector.type(event.tag)]))
            BASE_DISTANCE * (config_value || 0)
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
