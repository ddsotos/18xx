# frozen_string_literal: true

require_relative 'track_tile_manifest'

module Engine
  module Game
    module GRotLA
      # Engine tile DSL traced from the second-printing component illustration.
      # Edge 0 is the upper-right side of the printed tile and numbering proceeds
      # clockwise. Because tiles rotate in play, only relative edge geometry is
      # significant.
      module TrackTiles
        SPECIAL_LABELS = {
          star: 'S',
          eastern_mining: 'EM',
          northern_port: 'NP',
        }.freeze

        PATH_SPECS = {
          'RLA-Y01' => [[0, 2]],
          'RLA-Y07' => [[2, 5]],
          'RLA-Y08' => [[1, 2]],
          'RLA-G01' => [[2, 5], [0, 2]],
          'RLA-G02' => [[2, 5], [2, 4]],
          'RLA-G03' => [[0, 2], [2, 4]],
          'RLA-G04' => [[1, 5], [3, 4]],
          'RLA-G05' => [[2, 5], [2, 3]],
          'RLA-G06' => [[2, 5], [1, 2]],
          'RLA-G07' => [[0, 2], [3, 4]],
          'RLA-G08' => [[1, 2], [2, 3]],
          'RLA-G09' => [[2, 4], [1, 2]],
          'RLA-G10' => [[0, 2], [2, 3]],
          'RLA-G11' => [[2, 4], [2, 3]],
          'RLA-G12' => [[0, 2], [1, 2]],
          'RLA-G16' => [[2, 5], [0, 3]],
          'RLA-G17' => [[0, 2], [3, 5]],
          'RLA-G18' => [[0, 2], [1, 3]],
          'RLA-G19' => [[2, 5], [1, 3]],
          'RLA-P01' => [[2, 5], [2, 4], [4, 5]],
          'RLA-P02' => [[2, 5], [0, 2], [0, 4], [4, 5]],
          'RLA-P03' => [[2, 5], [1, 4], [1, 5], [2, 4]],
          'RLA-P04' => [[2, 5], [0, 2], [0, 5]],
          'RLA-P05' => [[2, 5], [3, 5], [2, 4], [3, 4]],
          'RLA-P06' => [[2, 5], [0, 4], [2, 4], [0, 5]],
          'RLA-P07' => [[0, 2], [0, 4], [2, 4]],
          'RLA-P08' => [[2, 5], [0, 2], [2, 4]],
          'RLA-P09' => [[2, 4], [3, 4], [2, 3]],
          'RLA-P10' => [[3, 5], [2, 4], [4, 5], [2, 3]],
          'RLA-P15' => [[2, 5], [0, 3], [0, 5], [2, 3]],
          'RLA-B01' => [[0, 2]],
          'RLA-B02' => [[2, 5]],
          'RLA-B03' => [[1, 2]],
        }.transform_values { |paths| paths.map(&:freeze).freeze }.freeze

        # Each white circle in the component art is a hub-token spot, not a
        # separate city. The slot count therefore increases while city count
        # remains one throughout upgrades.
        CITY_SPECS = {
          'RLA-Y02' => [20, 1, [2, 5], nil],
          'RLA-Y03' => [20, 1, [0, 2], nil],
          'RLA-Y04' => [20, 1, [2, 5], :star],
          'RLA-Y05' => [20, 1, [0, 2], :star],
          'RLA-Y06' => [20, 1, [1, 2], :star],
          'RLA-Y09' => [20, 1, [1, 2], nil],
          'RLA-G13' => [30, 2, [2, 3, 4, 5], nil],
          'RLA-G14' => [30, 2, [0, 2, 4, 5], nil],
          'RLA-G15' => [30, 2, [0, 2, 3, 5], nil],
          'RLA-G20' => [30, 2, [2, 3, 4, 5], :star],
          'RLA-G21' => [30, 2, [0, 2, 3, 5], :star],
          'RLA-G22' => [30, 2, [0, 2, 4, 5], :star],
          'RLA-G23' => [30, 2, [2, 3], :eastern_mining],
          'RLA-G24' => [30, 2, [1, 2, 3, 4], :northern_port],
          'RLA-P11' => [40, 2, [0, 2, 3, 4, 5], nil],
          'RLA-P12' => [40, 3, [0, 1, 2, 3, 5], :star],
          'RLA-P13' => [40, 3, [2, 3, 4], :eastern_mining],
          'RLA-P14' => [40, 4, [1, 2, 3, 4], :northern_port],
          'RLA-X01' => [50, 2, [0, 1, 2, 3, 4], nil],
          'RLA-X02' => [50, 3, [0, 1, 2, 3, 4], :star],
          'RLA-X03' => [50, 3, [1, 2, 3, 4], :eastern_mining],
        }.transform_values do |spec|
          spec[2].freeze
          spec.freeze
        end.freeze

        VECTORIZED_IDS = (PATH_SPECS.keys + CITY_SPECS.keys).freeze
        MANIFEST_IDS = TrackTileManifest::TILES.map { |tile| tile[:id] }.freeze

        unless VECTORIZED_IDS.sort == MANIFEST_IDS.sort
          raise 'RotLA vector tile definitions do not match the physical manifest'
        end

        def self.path_code(paths)
          paths.map { |left, right| "path=a:#{left},b:#{right}" }.join(';')
        end

        def self.city_code(revenue, slots, exits, special)
          parts = ["city=revenue:#{revenue},slots:#{slots}"]
          parts.concat(exits.map { |edge| "path=a:#{edge},b:_0" })
          parts << "label=#{SPECIAL_LABELS.fetch(special)}" if special
          parts.join(';')
        end

        def self.code_for(tile_id)
          return path_code(PATH_SPECS.fetch(tile_id)) if PATH_SPECS.key?(tile_id)

          city_code(*CITY_SPECS.fetch(tile_id))
        end

        TILES = TrackTileManifest::TILES.to_h do |tile|
          definition = {
            'count' => tile[:count],
            'color' => tile[:color].to_s,
            'code' => code_for(tile[:id]),
          }.freeze
          [tile[:id], definition]
        end.freeze
      end
    end
  end
end
