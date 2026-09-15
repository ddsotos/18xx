# frozen_string_literal: true

require_relative '../../hex'
require_relative 'map_geometry'

module Engine
  module Game
    module GRotLA
      # Converts the map's axial coordinates into the doubled coordinates used
      # by Engine::Hex's flat layout. No map or terrain data is implied here.
      module EngineMap
        AXIAL_DIRECTIONS = MapGeometry::DIRECTIONS
        AXIAL_TO_EDGE = {
          [1, 0] => 5,
          [0, 1] => 0,
          [-1, 1] => 1,
          [-1, 0] => 2,
          [0, -1] => 3,
          [1, -1] => 4,
        }.freeze

        module_function

        # Return the Engine::Hex edge corresponding to an axial direction.
        def edge_for(direction)
          direction = direction.dup if direction.is_a?(Array)
          AXIAL_TO_EDGE[direction] || raise(ArgumentError, "unknown axial direction: #{direction.inspect}")
        end

        # Build a hash keyed by the original axial coordinate. Adjacent supplied
        # coordinates are linked in both Engine::Hex neighbor collections.
        def build(coordinates)
          points = validate_coordinates(coordinates)
          coordinate_map = self.coordinates(points)
          hexes = points.to_h do |q, r|
            [[q, r].freeze, Hex.new(coordinate_map[[q, r]], layout: :flat)]
          end

          by_axial = hexes
          points.each do |q, r|
            AXIAL_DIRECTIONS.each do |dq, dr|
              neighbor = by_axial[[q + dq, r + dr]]
              next unless neighbor

              edge = edge_for([dq, dr])
              hex = by_axial[[q, r]]
              hex.all_neighbors[edge] = neighbor
              hex.neighbors[edge] = neighbor
            end
          end
          hexes
        end

        # Return the normalized Engine coordinate for each original axial point.
        def coordinates(points)
          points = validate_coordinates(points)
          offsets = normalization_offsets(points)
          max_x = points.map { |q, _r| q + offsets[0] }.max
          raise ArgumentError, 'map exceeds Engine::Hex coordinate columns (A..AZ)' if max_x && max_x >= Hex::LETTERS.size

          points.to_h do |q, r|
            x = q + offsets[0]
            y = q + (2 * r) + offsets[1]
            [[q, r].freeze, coordinate_name(x, y)]
          end
        end

        def coordinate_name(x, y)
          "#{Hex::LETTERS.fetch(x)}#{y + 1}"
        end

        def validate_coordinates(coordinates)
          valid = coordinates.is_a?(Array) && coordinates.all? do |point|
            point.is_a?(Array) && point.size == 2 && point.all?(Integer)
          end
          raise ArgumentError, 'coordinates must contain pairs of integers' unless valid
          raise ArgumentError, 'coordinates must be distinct' unless coordinates.uniq.size == coordinates.size

          coordinates.map { |q, r| [q, r] }
        end
        private_class_method :validate_coordinates

        def normalization_offsets(points)
          return [0, 0] if points.empty?

          x_values = points.map(&:first)
          y_values = points.map { |q, r| q + (2 * r) }
          x_offset = -x_values.min
          y_offset = -y_values.min
          y_offset += 1 if (x_offset - y_offset).odd?
          [x_offset, y_offset]
        end
        private_class_method :normalization_offsets
      end
    end
  end
end
