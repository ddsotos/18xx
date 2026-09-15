# frozen_string_literal: true

require_relative 'map_builder'
require_relative 'setup_config'
require_relative 'setup'

module Engine
  module Game
    module GRotLA
      # Include after Setup in the future Game class. The map must be compiled
      # before Base#initialize creates corporations, reservations, hexes and graph.
      module FixedMap
        attr_reader :rotla_map_builder

        def self.included(base)
          raise ArgumentError, 'Include GRotLA::Setup before GRotLA::FixedMap' unless base.ancestors.include?(Setup)
          raise ArgumentError, 'RotLA Game must define its physical MAP_CATALOG' unless base.const_defined?(:MAP_CATALOG, false)
        end

        def initialize(names, settings: nil, **kwargs)
          config = SetupConfig.from_settings(settings)
          @rotla_map_builder = MapBuilder.new(config, catalog: self.class::MAP_CATALOG)
          super
        end

        def game_hexes
          @rotla_map_builder.game_hexes
        end

        def init_hexes(companies, corporations)
          @rotla_map_builder.apply_rotations!(super)
        end
      end
    end
  end
end
