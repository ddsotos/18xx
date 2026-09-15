# frozen_string_literal: true

require 'json'
require_relative 'minor_tableau'
require_relative 'setup_config'

module Engine
  module Game
    module GRotLA
      # Included by the future RotLA Game; leaves other titles' construction and replay unchanged.
      module Setup
        attr_reader :rotla_minor_tableau, :rotla_setup_config

        def initialize(names, settings: nil, **kwargs)
          @rotla_setup_config = SetupConfig.from_settings(settings)
          valid_players = names.respond_to?(:size) && names.size == @rotla_setup_config.to_h['player_count']
          raise ArgumentError, 'RotLA requires exactly four players' unless valid_players

          @rotla_minor_tableau = MinorTableau.new(
            columns: @rotla_setup_config.to_h.fetch('minor_tableau'),
          )
          @rotla_settings = JSON.parse(JSON.generate(settings))
          @rotla_settings['rotla'] = @rotla_setup_config.to_h
          @rotla_clone_options = kwargs.except(:actions, :at_action)
          super(names, settings: rotla_settings, **kwargs)
          @init_kwargs[:settings] = rotla_settings
        end

        def rotla_settings
          snapshot = JSON.parse(JSON.generate(@rotla_settings))
          # Persist effective values as well as the manifest, including a generated seed.
          snapshot['seed'] = @seed if @seed
          snapshot['optional_rules'] = @optional_rules.map(&:to_s) if @optional_rules
          snapshot['use_engine_v2'] = @use_engine_v2 unless @use_engine_v2.nil?
          snapshot['pin'] = @rotla_clone_options[:pin] if @rotla_clone_options[:pin]
          snapshot
        end

        def clone(actions)
          self.class.new(
            @names.dup,
            **@rotla_clone_options,
            id: @id,
            seed: @seed,
            optional_rules: @optional_rules.dup,
            settings: rotla_settings,
            actions: actions
          )
        end
      end
    end
  end
end
