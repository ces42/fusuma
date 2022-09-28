# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/plugin/executors/command_executor"
require "./lib/fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Executors
      RSpec.describe CommandExecutor do
        before do
          index = Config::Index.new([:dummy, 1, :direction])
          record = Events::Records::IndexRecord.new(index: index)
          @event = Events::Event.new(tag: "dummy_detector", record: record)
          @executor = CommandExecutor.new
        end

        around do |example|
          ConfigHelper.load_config_yml = <<~CONFIG
            dummy:
              1:
                direction:
                  command: 'echo dummy'
                  interval: 1
          CONFIG

          example.run

          Config.custom_path = nil
        end

        describe "#execute" do
          it "spawn" do
            command = "echo dummy"
            env = {}
            expect(Process).to receive(:spawn).with(env, command)
            expect(Process).to receive(:detach).with(anything)
            @executor.execute(@event)
          end
        end

        describe "#executable?" do
          context "detector is matched with config file" do
            it { expect(@executor.executable?(@event)).to be_truthy }
          end

          context "detector is NOT matched with config file" do
            before do
              @event.tag = "invalid"
            end
            it { expect(@executor.executable?(@event)).to be_falsey }
          end
        end
      end
    end
  end
end
