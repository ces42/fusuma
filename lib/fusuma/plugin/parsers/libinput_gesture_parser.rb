# frozen_string_literal: true

require_relative "../events/records/record"
require_relative "../events/records/gesture_record"

module Fusuma
  module Plugin
    module Parsers
      # parse libinput and generate gesture record
      class LibinputGestureParser < Parser
        DEFAULT_SOURCE = "libinput_command_input"

        # @param record [String]
        # @return [Records::GestureRecord, nil]
        def parse_record(record)
          case line = record.to_s
          when /GESTURE_SWIPE|GESTURE_PINCH|GESTURE_HOLD/
            gesture, status, finger, delta = parse_libinput(line)
          else
            return
          end

          Events::Records::GestureRecord.new(status: status,
            gesture: gesture,
            finger: finger,
            delta: delta)
        end

        private

        def parse_libinput(line)
          _device, event_name, _time, other = line.strip.split(nil, 4)
          finger, other = other.split(nil, 2)

          gesture, status = *detect_gesture(event_name)

          status = "cancelled" if gesture == "hold" && status == "end" && other == "cancelled"
          delta = parse_delta(other)
          [gesture, status, finger, delta]
        end

        def detect_gesture(event_name)
          event_name =~ /GESTURE_(SWIPE|PINCH|HOLD)_(BEGIN|UPDATE|END)/
          gesture = Regexp.last_match(1).downcase
          status = Regexp.last_match(2).downcase
          [gesture, status]
        end

        def parse_delta(line)
          return if line.nil?

          move_x, move_y, unaccelerated_x, unaccelerated_y, _, zoom, _, rotate =
            line.tr("/|(|)", " ").split
          Events::Records::GestureRecord::Delta.new(move_x.to_f, move_y.to_f,
            unaccelerated_x.to_f, unaccelerated_y.to_f,
            zoom.to_f, rotate.to_f)
        end
      end
    end
  end
end
