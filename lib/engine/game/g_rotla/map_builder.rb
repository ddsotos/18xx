# frozen_string_literal: true

require_relative 'setup_config'
require_relative 'map_geometry'
require_relative 'engine_map'
require_relative '../../tile'

module Engine
  module Game
    module GRotLA
      # Compile placements against a supplied physical-tile catalog. Catalog codes
      # use Engine tile DSL edges at rotation zero, not axial direction indices.
      class MapBuilder
        CITY_TYPES = %w[basic capital company].freeze

        def initialize(config, catalog:)
          manifest = config.to_h.fetch('map_manifest')
          valid_catalog = catalog.is_a?(Hash) && catalog.keys.all?(String)
          raise ArgumentError, 'Map catalog must be keyed by physical copy_id strings' unless valid_catalog

          placements = manifest['placements']
          unless placements.map { |p| p['copy_id'] }.sort == catalog.keys.sort
            raise ArgumentError, 'Placements must use every catalog copy exactly once'
          end

          @cells = placements.flat_map { |placement| expand(placement, catalog.fetch(placement['copy_id'])) }
          coordinates = EngineMap.coordinates(@cells.map { |cell| cell[:axial] })
          @cells.each { |cell| cell[:coordinate] = coordinates.fetch(cell[:axial]) }
          apply_projects!(manifest['projects'])
        end

        # Return data in Base#game_hexes format, detached on every call.
        def game_hexes
          @cells.each_with_object({}) do |cell, result|
            result[cell[:color]] ||= {}
            result[cell[:color]][[cell[:coordinate].dup]] = cell[:code].dup
          end
        end

        # Base must see rotated paths before constructing cities and graph caches.
        def apply_rotations!(hexes)
          expected = @cells.to_h { |cell| [cell[:coordinate], cell[:rotation]] }
          unless hexes.map(&:coordinates).sort == expected.keys.sort
            raise ArgumentError, 'Engine hexes do not match the compiled map'
          end

          hexes.each { |hex| hex.tile.rotate!(expected.fetch(hex.coordinates)) }
          hexes
        end

        # Resolve semantic map-city metadata only after Base has constructed the
        # actual Engine::Part::City objects. Keeping this classification in the
        # physical catalog makes it survive map placement and rotation without
        # inferring rules from generated Engine coordinates.
        def cities_by_type(game, type)
          type = type.to_s
          raise ArgumentError, "Unknown RotLA city type: #{type}" unless CITY_TYPES.include?(type)

          @cells.flat_map do |cell|
            next [] unless cell[:city_type] == type

            hex = game.hex_by_id(cell[:coordinate])
            raise ArgumentError, "Compiled RotLA hex #{cell[:coordinate]} is missing" unless hex

            # Classification belongs to the map hex rather than a preprinted
            # city ordinal, so a later tile upgrade returns its current cities.
            hex.tile.cities
          end
        end

        def coordinates_by_type(type)
          type = type.to_s
          raise ArgumentError, "Unknown RotLA city type: #{type}" unless CITY_TYPES.include?(type)

          @cells.filter_map { |cell| cell[:coordinate] if cell[:city_type] == type }
        end

        def company_home_coordinates
          @cells
            .select { |cell| cell[:city_type] == 'company' }
            .sort_by { |cell| cell[:copy_id] }
            .map { |cell| cell[:coordinate] }
        end

        private

        def apply_projects!(projects)
          selected = []
          projects.each do |project|
            unless project['effect_type'] == 'capital'
              raise ArgumentError, "Unsupported map project effect: #{project['effect_type']}"
            end

            target = project['target_city_id']
            raise ArgumentError, 'Capital projects must select different cities' if selected.include?(target)

            cell = @cells.find { |candidate| candidate[:coordinate] == target }
            valid_target = cell && cell[:city_type] == 'basic' && Engine::Tile.decode(cell[:code]).any?(&:city?)
            raise ArgumentError, "Capital project target is not a basic city: #{target}" unless valid_target

            cell[:city_type] = 'capital'.freeze
            selected << target
          end
        end

        def expand(placement, definition)
          valid_definition = definition.is_a?(Array) && definition.size == 3 && definition.all?(Hash)
          raise ArgumentError, 'Each map copy must define three hexes' unless valid_definition

          cells = MapGeometry.transform(
            definition.map { |cell| cell['axial'] }, origin: placement['origin'], rotation: placement['rotation']
          )
          definition.zip(cells).map do |cell, axial|
            valid_color = %w[white yellow green brown gray red purple blue].include?(cell['color'])
            valid_cell = valid_color && cell['code'].is_a?(String)
            raise ArgumentError, 'Catalog hexes require a supported color and tile DSL code' unless valid_cell

            city_type = cell['city_type']
            city_count = Engine::Tile.decode(cell['code']).count(&:city?)
            type_matches_city = city_count.zero? ? city_type.nil? : CITY_TYPES.include?(city_type)
            valid_city_type = cell.key?('city_type') && type_matches_city
            unless valid_city_type
              raise ArgumentError, 'Catalog city_type must classify each city hex as basic, capital, or company'
            end

            {
              copy_id: placement['copy_id'].dup.freeze,
              axial: axial,
              color: cell['color'].to_sym,
              code: rotate_static_edges(cell['code'], placement['rotation']),
              rotation: placement['rotation'],
              city_type: city_type&.dup&.freeze,
            }
          end
        end

        # Tile#rotate! rotates paths, while border and stub edges are static fields.
        def rotate_static_edges(code, rotation)
          if rotation.positive? && code.split(';').any? { |part| part.start_with?('partition=') }
            raise ArgumentError, 'Rotated partition geometry is not supported yet'
          end

          code.split(';').map do |part|
            next part unless part.start_with?('border=', 'stub=')

            part.gsub(/edge:(\d+)/) do
              edge = Regexp.last_match(1).to_i
              raise ArgumentError, 'Border edge must be between 0 and 5' unless (0..5).cover?(edge)

              "edge:#{(edge + rotation) % 6}"
            end
          end.join(';')
        end
      end
    end
  end
end
