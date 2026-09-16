# frozen_string_literal: true

require 'json'
require_relative 'engine_map'
require_relative 'map'
require_relative 'map_geometry'

module Engine
  module Game
    module GRotLA
      # Replayable pre-game placement state used by the Hotseat creation page.
      # The physical drawings are provisional; copy ids, placement choices and
      # capital targets are nevertheless stable save data.
      class MapSetup
        CAPITAL_PROJECT_IDS = %w[capital-01 capital-02 capital-03].freeze

        attr_reader :placements, :projects

        def initialize(journal: [], catalog: Map::MAP_CATALOG, player_count: 4)
          @catalog = catalog
          @player_count = player_count
          @tile_order = @catalog.keys.freeze
          @journal = []
          @placements = []
          @projects = []
          replay!(copy(journal))
        end

        def phase
          return :map_tiles if @placements.size < @tile_order.size
          return :capital_projects if @projects.size < CAPITAL_PROJECT_IDS.size

          :complete
        end

        def complete?
          phase == :complete
        end

        def current_copy_id
          case phase
          when :map_tiles
            @tile_order[@placements.size]
          when :capital_projects
            CAPITAL_PROJECT_IDS[@projects.size]
          end
        end

        def current_actor_index
          @journal.size % @player_count
        end

        def occupied_slot_indices
          origins = @placements.map { |placement| placement.fetch('origin') }
          Map::PIECE_ORIGINS.each_index.select { |index| origins.include?(Map::PIECE_ORIGINS[index]) }
        end

        def legal_slot_indices(rotation)
          return [] unless phase == :map_tiles

          Map::PIECE_ORIGINS.each_index.select { |slot_index| legal_placement?(slot_index, rotation) }
        end

        def place!(slot_index:, rotation:)
          raise ArgumentError, 'Map tiles are not currently being placed' unless phase == :map_tiles
          valid_rotation = rotation.is_a?(Integer) && (0..5).cover?(rotation)
          raise ArgumentError, 'Rotation must be an integer from 0 to 5' unless valid_rotation
          raise ArgumentError, 'Chosen map slot is not legal' unless legal_placement?(slot_index, rotation)

          entry = {
            'type' => 'place',
            'actor_index' => current_actor_index,
            'copy_id' => current_copy_id,
            'origin' => Map::PIECE_ORIGINS.fetch(slot_index).dup,
            'rotation' => rotation,
          }
          apply_place!(entry)
          @journal << entry
          self
        end

        def capital_candidates
          return [] if @placements.empty?

          coordinate_map = coordinate_map_for_placements
          selected = @projects.map { |project| project.fetch('target_city_id') }
          @placements.flat_map do |placement|
            definition = @catalog.fetch(placement.fetch('copy_id'))
            transformed = MapGeometry.transform(
              definition.map { |cell| cell.fetch('axial') },
              origin: placement.fetch('origin'),
              rotation: placement.fetch('rotation'),
            )
            definition.zip(transformed).filter_map do |cell, axial|
              next unless cell.fetch('city_type') == 'basic'

              coordinate = coordinate_map.fetch(axial)
              coordinate unless selected.include?(coordinate)
            end
          end.sort
        end

        def choose_capital!(target_city_id:)
          raise ArgumentError, 'Capital projects are not currently being placed' unless phase == :capital_projects
          unless capital_candidates.include?(target_city_id)
            raise ArgumentError, 'Chosen capital target is not a basic city'
          end

          entry = {
            'type' => 'choose_project_target',
            'actor_index' => current_actor_index,
            'project_copy_id' => current_copy_id,
            'target_city_id' => target_city_id,
          }
          apply_capital!(entry)
          @journal << entry
          self
        end

        def journal
          copy(@journal)
        end

        def rotla_settings
          raise ArgumentError, 'Map setup must be complete before creating a game' unless complete?

          data = copy(Map::DEFAULT_SETTINGS.fetch('rotla'))
          data['map_id'] = 'long4-custom-v1'
          data['setup_journal'] = journal
          data['map_manifest'] = {
            'map_id' => data['map_id'],
            'map_version' => data.fetch('map_manifest_version'),
            'placements' => copy(@placements),
            'projects' => copy(@projects),
          }
          data
        end

        private

        def replay!(journal)
          journal.each do |entry|
            expected_actor = @journal.size % @player_count
            raise ArgumentError, 'Map setup journal actor is out of turn' unless entry['actor_index'] == expected_actor

            case entry['type']
            when 'place'
              unless entry['copy_id'] == current_copy_id
                raise ArgumentError, 'Map setup journal places an unexpected tile'
              end

              slot_index = Map::PIECE_ORIGINS.index(entry['origin'])
              unless legal_placement?(slot_index, entry['rotation'])
                raise ArgumentError, 'Map setup journal uses an unknown slot'
              end

              apply_place!(entry)
            when 'choose_project_target'
              valid_project = phase == :capital_projects && entry['project_copy_id'] == current_copy_id
              raise ArgumentError, 'Map setup journal uses an unexpected capital project' unless valid_project
              unless capital_candidates.include?(entry['target_city_id'])
                raise ArgumentError, 'Map setup journal uses an invalid capital target'
              end

              apply_capital!(entry)
            else
              raise ArgumentError, 'Unknown map setup journal action'
            end
            @journal << entry
          end
        end

        def legal_placement?(slot_index, rotation)
          return false unless slot_index.is_a?(Integer) && Map::PIECE_ORIGINS[slot_index]
          return false unless rotation.is_a?(Integer) && (0..5).cover?(rotation)
          return false if occupied_slot_indices.include?(slot_index)

          candidate = transformed_cells(current_copy_id, Map::PIECE_ORIGINS.fetch(slot_index), rotation)
          occupied = @placements.flat_map do |placement|
            transformed_cells(placement.fetch('copy_id'), placement.fetch('origin'), placement.fetch('rotation'))
          end
          (candidate & occupied).empty?
        end

        def transformed_cells(copy_id, origin, rotation)
          MapGeometry.transform(
            @catalog.fetch(copy_id).map { |cell| cell.fetch('axial') },
            origin: origin,
            rotation: rotation,
          )
        end

        def coordinate_map_for_placements
          points = @placements.flat_map do |placement|
            transformed_cells(placement.fetch('copy_id'), placement.fetch('origin'), placement.fetch('rotation'))
          end
          EngineMap.coordinates(points)
        end

        def apply_place!(entry)
          @placements << {
            'copy_id' => entry.fetch('copy_id').dup,
            'origin' => entry.fetch('origin').dup,
            'rotation' => entry.fetch('rotation'),
          }
        end

        def apply_capital!(entry)
          @projects << {
            'project_copy_id' => entry.fetch('project_copy_id').dup,
            'target_city_id' => entry.fetch('target_city_id').dup,
            'effect_type' => 'capital',
          }
        end

        def copy(value)
          JSON.parse(JSON.generate(value))
        end
      end
    end
  end
end
