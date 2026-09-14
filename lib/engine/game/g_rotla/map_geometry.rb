# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # Axial geometry only. Direction indices are not Engine::Hex edge numbers.
      module MapGeometry
        DIRECTIONS = [
          [1, 0], [0, 1], [-1, 1],
          [-1, 0], [0, -1], [1, -1],
        ].map(&:freeze).freeze

        module_function

        def rotate(coordinate, turns = 1)
          q, r = coordinate!(coordinate)
          rotation!(turns).times { q, r = -r, q + r }
          [q, r].freeze
        end

        def translate(coordinate, offset)
          q, r = coordinate!(coordinate)
          dq, dr = coordinate!(offset)
          [q + dq, r + dr].freeze
        end

        def transform(coordinates, origin: [0, 0], rotation: 0)
          coordinate!(origin)
          rotation!(rotation)
          coordinates!(coordinates).map do |point|
            translate(rotate(point, rotation), origin)
          end.freeze
        end

        def shared_edges(left, right)
          validate_no_overlap!(left, right)
          right_set = right.to_h { |point| [point, true] }
          left.sum do |q, r|
            DIRECTIONS.count { |dq, dr| right_set.key?([q + dq, r + dr]) }
          end
        end

        def validate_no_overlap!(left, right)
          raise ArgumentError, 'coordinate sets overlap' if overlap?(left, right)

          true
        end

        def overlap?(left, right)
          !(coordinates!(left) & coordinates!(right)).empty?
        end

        def coordinates!(coordinates)
          raise ArgumentError, 'coordinates must be an Array' unless coordinates.is_a?(Array)

          coordinates.each { |point| coordinate!(point) }
          raise ArgumentError, 'coordinates must be distinct' unless coordinates.uniq.size == coordinates.size

          coordinates
        end
        private_class_method :coordinates!

        def coordinate!(coordinate)
          unless coordinate.is_a?(Array) && coordinate.size == 2 && coordinate.all? { |value| value.is_a?(Integer) }
            raise ArgumentError, 'coordinate must contain two integers'
          end

          coordinate
        end
        private_class_method :coordinate!

        def rotation!(turns)
          unless turns.is_a?(Integer) && (0..5).cover?(turns)
            raise ArgumentError, 'rotation must be an integer from 0 to 5'
          end

          turns
        end
        private_class_method :rotation!
      end
    end
  end
end
