# frozen_string_literal: true

require "spec_helper"
require "./lib/fusuma/config"
require "./lib/fusuma/config/searcher"

# spec for Config
module Fusuma
  RSpec.describe Config::Searcher do
    around do |example|
      ConfigHelper.load_config_yml = <<~CONFIG
        swipe:
          3:
            left:
              command: 'alt+Left'
            right:
              command: 'alt+Right'
          4:
            left:
              command: 'super+Left'
            right:
              command: 'super+Right'
        pinch:
          in:
            command: 'ctrl+plus'
          out:
            command: 'ctrl+minus'
      CONFIG

      example.run

      ConfigHelper.clear_config_yml
    end

    describe ".search" do
      let(:index) { nil }
      let(:location) { Config.instance.keymap[0] }
      let(:search) { Config::Searcher.new.search(index, location: location) }
      context "index correct order" do
        let(:index) { Config::Index.new %w[pinch in command] }
        it { expect(Config::Searcher.new.search(index, location: location)).to eq "ctrl+plus" }
      end

      context "index incorrect order" do
        let(:index) { Config::Index.new %w[in pinch 2 command] }
        it { expect(Config::Searcher.new.search(index, location: location)).not_to eq "ctrl+plus" }
      end

      context "with Skip condtions" do
        context "when index includes skippable key" do
          let(:index) do
            Config::Index.new [
              Config::Index::Key.new("pinch"),
              Config::Index::Key.new(2, skippable: true),
              Config::Index::Key.new("out"),
              Config::Index::Key.new("command")
            ]
          end
          it "detects ctrl+minus with skip" do
            value = Config::Searcher.new.search(index, location: location)
            expect(value).to eq("ctrl+minus")
          end
        end

        context "when index includes skippable key at first" do
          let(:index) do
            Config::Index.new [
              Config::Index::Key.new(:hoge, skippable: true),
              Config::Index::Key.new(:fuga, skippable: true),
              Config::Index::Key.new("pinch"),
              Config::Index::Key.new("in"),
              Config::Index::Key.new(:piyo, skippable: true),
              Config::Index::Key.new("command")
            ]
          end
          it "detects ctrl+plus with skip" do
            value = Config::Searcher.new.search(index, location: location)
            expect(value).to eq("ctrl+plus")
          end
        end

        context "with begin/update/end" do
          around do |example|
            ConfigHelper.load_config_yml = <<~CONFIG
              swipe:
                3:
                  begin:
                    command: 'echo begin'
                  update:
                    command: 'echo update'
                  end:
                    command: 'echo end'
                    keypress:
                      LEFTCTRL:
                        command: 'echo end+ctrl'
            CONFIG

            example.run

            ConfigHelper.clear_config_yml
          end

          context "without keypress" do
            let(:index) do
              Config::Index.new [
                Config::Index::Key.new(:swipe),
                Config::Index::Key.new(3),
                Config::Index::Key.new("left", skippable: true),
                Config::Index::Key.new("end"),
                Config::Index::Key.new("command")
              ]
            end

            it "detects with skip" do
              value = Config::Searcher.new.search(index, location: location)
              expect([value]).to eq(["echo end"])
            end
          end
          context "with keypress" do
            context "with valid key existing in config.yml" do
              let(:index) do
                Config::Index.new [
                  Config::Index::Key.new(:swipe),
                  Config::Index::Key.new(3),
                  Config::Index::Key.new("left", skippable: true),
                  Config::Index::Key.new("end"),
                  Config::Index::Key.new("keypress", skippable: true),
                  Config::Index::Key.new("LEFTCTRL", skippable: true),
                  Config::Index::Key.new("command")
                ]
              end
              it "detects end+ctrl with skip" do
                value = Config::Searcher.new.search(index, location: location)
                expect(value).to eq("echo end+ctrl")
              end
            end
            context "with non-existing key not existing in config.yml" do
              let(:index) do
                Config::Index.new [
                  Config::Index::Key.new(:swipe),
                  Config::Index::Key.new(3),
                  Config::Index::Key.new("up", skippable: true),
                  Config::Index::Key.new("end"),
                  Config::Index::Key.new("keypress", skippable: true),
                  Config::Index::Key.new("LEFTSHIFT", skippable: true), # Invalid key
                  Config::Index::Key.new("command")
                ]
              end
              it "detects end with skip (fallback to no keypress)" do
                value = Config::Searcher.new.search(index, location: location)
                expect(value).to eq("echo end")
              end
            end
          end
        end
      end
    end

    describe ".find_context" do
      around do |example|
        ConfigHelper.load_config_yml = <<~CONFIG
          ---
          context: { plugin_defaults: "libinput_command_input" }
          plugin:
            inputs:
              libinput_command_input:
          ---
          context: { plugin_defaults: "sendkey_executor" }
          plugin:
            executors:
              sendkey_executor:
                device_name: keyboard|Keyboard|KEYBOARD
        CONFIG

        example.run

        ConfigHelper.clear_config_yml
      end

      it "should find matched context and matched value" do
        request_context = {plugin_defaults: "sendkey_executor"}
        fallbacks = [:no_context, :plugin_default_context]

        device_name = nil
        matched = Config::Searcher.find_context(request_context, fallbacks) do
          # search device_name from sendkey_executor context
          device_name = Config.search(Config::Index.new(%w[plugin executors sendkey_executor device_name]))
        end

        expect(matched).to eq request_context
        expect(device_name).to eq "keyboard|Keyboard|KEYBOARD"
      end
    end

    describe "private_method: :cache" do
      it "should cache command" do
        key = %w[event_type finger direction command].join(",")
        value = "shourtcut string"
        searcher = Config::Searcher.new
        searcher.send(:cache, key) { value }
        expect(searcher.send(:cache, key)).to eq value
      end
    end
  end
end
