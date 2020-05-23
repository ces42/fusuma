# frozen_string_literal: true

require_relative './version.rb'
require_relative './libinput_command.rb'
require_relative './multi_logger.rb'

module Fusuma
  # Output Environment information
  class Environment
    class << self
      def dump_information
        MultiLogger.info '---------------------------------------------'
        print_version
        MultiLogger.info '---------------------------------------------'
        print_enabled_plugins
        MultiLogger.info '---------------------------------------------'
      end

      def print_version
        MultiLogger.info "Fusuma: #{VERSION}"
        MultiLogger.info "libinput: #{LibinputCommand.new.version}"
        MultiLogger.info "OS: #{`uname -rsv`}".strip
        MultiLogger.info "Distribution: #{`cat /etc/issue`}".strip
        MultiLogger.info "Desktop session: #{`echo $DESKTOP_SESSION $XDG_SESSION_TYPE`}".strip
      end

      def print_enabled_plugins
        MultiLogger.info 'Enabled Plugins: '
        Plugin::Manager.plugins
                       .reject { |k, _v| k.to_s =~ /Base/ }
                       .map { |_base, plugins| plugins.map { |plugin| "  #{plugin}" } }
                       .flatten.sort.each { |name| MultiLogger.info(name) }
      end

      def print_device_list
        Plugin::Filters::LibinputDeviceFilter.new.keep_device.all.map do |device|
          puts device.name
        end
      end
    end
  end
end