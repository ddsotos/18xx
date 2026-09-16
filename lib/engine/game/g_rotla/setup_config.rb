# frozen_string_literal: true

require_relative 'minor_tableau'

module Engine
  module Game
    module GRotLA
      # Structural validation only: the official component catalog must also be checked before starting a game.
      class SetupConfig
        VERSION = 2
        MAP_MANIFEST_VERSION = 1
        RULESET = 'en-second-printing'
        FIELDS = %w[
          schema_version ruleset mode player_count map_manifest_version map_id map_manifest minor_tableau setup_journal
        ].freeze

        def self.from_settings(settings)
          valid_settings = settings.is_a?(Hash) && settings.key?('rotla')
          raise ArgumentError, 'Missing settings.rotla' unless valid_settings

          new(settings['rotla'])
        end

        def initialize(data)
          @data = copy(data)
          validate!
          freeze_value(@data)
        end

        # Return a detached JSON-compatible snapshot, including nested strings and arrays.
        def to_h
          copy(@data)
        end

        private

        def copy(value)
          case value
          when Hash
            value.to_h do |key, item|
              raise ArgumentError, 'RotLA settings require string keys' unless key.is_a?(String)

              [key.dup, copy(item)]
            end
          when Array
            value.map { |item| copy(item) }
          when String
            value.dup
          when Integer, NilClass, TrueClass, FalseClass
            value
          else
            raise ArgumentError, 'RotLA settings contain an unsupported value'
          end
        end

        def freeze_value(value)
          case value
          when Hash
            value.each do |key, item|
              key.freeze
              freeze_value(item)
            end
          when Array
            value.each { |item| freeze_value(item) }
          end
          value.freeze
        end

        def fields!(value, fields, label)
          return if value.is_a?(Hash) && value.keys.sort == fields.sort

          raise ArgumentError, "#{label} requires exactly: #{fields.join(', ')}"
        end

        def id!(value, label)
          valid_id = value.is_a?(String) && !value.strip.empty?
          raise ArgumentError, "#{label} must be a nonempty string" unless valid_id
        end

        def validate!
          fields!(@data, FIELDS, 'RotLA settings')
          {
            'schema_version' => VERSION,
            'ruleset' => RULESET,
            'mode' => 'long',
            'player_count' => 4,
            'map_manifest_version' => MAP_MANIFEST_VERSION,
          }.each do |key, expected|
            raise ArgumentError, "Unsupported RotLA #{key}" unless @data[key] == expected
          end
          id!(@data['map_id'], 'map_id')
          MinorTableau.new(columns: @data['minor_tableau'])
          manifest = @data['map_manifest']
          fields!(manifest, %w[map_id map_version placements projects], 'map_manifest')
          valid_manifest = manifest['map_id'] == @data['map_id'] && manifest['map_version'] == MAP_MANIFEST_VERSION
          raise ArgumentError, 'Map manifest identity/version does not match settings' unless valid_manifest

          placements!(manifest['placements'])
          projects!(manifest['projects'])
          setup_journal!(@data['setup_journal'], manifest)
        end

        def placements!(placements)
          valid_placements = placements.is_a?(Array) && !placements.empty?
          raise ArgumentError, 'Map placements must be a nonempty array' unless valid_placements

          ids = []
          placements.each do |placement|
            fields!(placement, %w[copy_id origin rotation], 'placement')
            id!(placement['copy_id'], 'copy_id')
            raise ArgumentError, 'Duplicate map copy_id' if ids.include?(placement['copy_id'])

            ids << placement['copy_id']
            origin = placement['origin']
            valid_origin = origin.is_a?(Array) && origin.size == 2 && origin.all? { |n| n.is_a?(Integer) }
            raise ArgumentError, 'Placement origin must contain two integers' unless valid_origin

            rotation = placement['rotation']
            valid_rotation = rotation.is_a?(Integer) && (0..5).cover?(rotation)
            raise ArgumentError, 'Placement rotation must be an integer from 0 to 5' unless valid_rotation
          end
        end

        def projects!(projects)
          raise ArgumentError, 'Map projects must be an array' unless projects.is_a?(Array)

          ids = []
          projects.each do |project|
            fields!(project, %w[project_copy_id target_city_id effect_type], 'project')
            project.each { |key, value| id!(value, key) }
            raise ArgumentError, 'Duplicate project_copy_id' if ids.include?(project['project_copy_id'])

            ids << project['project_copy_id']
          end
        end

        def setup_journal!(journal, manifest)
          raise ArgumentError, 'Map setup journal must be an array' unless journal.is_a?(Array)
          return if journal.empty?

          placements = []
          projects = []
          capital_phase = false
          journal.each_with_index do |entry, index|
            raise ArgumentError, 'Map setup journal entries must be objects' unless entry.is_a?(Hash)
            unless entry['actor_index'] == index % @data['player_count']
              raise ArgumentError, 'Map setup journal actor is out of turn'
            end

            case entry['type']
            when 'place'
              raise ArgumentError, 'Map tile cannot be placed after a capital project' if capital_phase

              fields!(entry, %w[type actor_index copy_id origin rotation], 'map setup placement')
              placement = entry.slice('copy_id', 'origin', 'rotation')
              placements!([placement])
              placements << placement
            when 'choose_project_target'
              capital_phase = true
              fields!(entry, %w[type actor_index project_copy_id target_city_id], 'capital project choice')
              id!(entry['project_copy_id'], 'project_copy_id')
              id!(entry['target_city_id'], 'target_city_id')
              projects << {
                'project_copy_id' => entry['project_copy_id'],
                'target_city_id' => entry['target_city_id'],
                'effect_type' => 'capital',
              }
            else
              raise ArgumentError, 'Unknown map setup journal action'
            end
          end

          unless placements == manifest['placements'] && projects == manifest['projects']
            raise ArgumentError, 'Map setup journal does not reproduce the finalized manifest'
          end
        end
      end
    end
  end
end
