# frozen_string_literal: true

require_relative 'track_tiles'

module Engine
  module Game
    module GRotLA
      # A deterministic four-player development map. It deliberately keeps the
      # physical-copy boundary and saved manifest used by the future verified
      # map, so replacing the provisional geometry does not affect round code.
      module Map
        MAP_ID = 'long4-playable-v0'
        PIECE_ORIGINS = [
          [0, 0], [2, 0], [4, 0], [6, 0],
          [0, 2], [2, 2], [4, 2], [6, 2],
          [0, 4], [2, 4], [4, 4], [6, 4],
        ].map(&:freeze).freeze

        COMPANY_HOME_COORDINATES = %w[A1 C3 E5 G7 A5 C7 E9 G11 A9 C11 E13].freeze

        CITY_CODE = 'city=revenue:yellow_20|green_30|purple_40|gray_50,slots:3;' \
                    'path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;' \
                    'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0'

        MAP_CATALOG = PIECE_ORIGINS.each_index.to_h do |index|
          copy_id = format('long4-%02d', index + 1)
          first_type = index < COMPANY_HOME_COORDINATES.size ? 'company' : 'basic'
          cells = [
            { 'axial' => [0, 0], 'color' => 'yellow', 'code' => CITY_CODE, 'city_type' => first_type },
            { 'axial' => [1, 0], 'color' => 'yellow', 'code' => CITY_CODE, 'city_type' => 'basic' },
            { 'axial' => [0, 1], 'color' => 'yellow', 'code' => CITY_CODE, 'city_type' => 'basic' },
          ]
          [copy_id, cells.map(&:freeze).freeze]
        end.freeze

        DEFAULT_SETTINGS = {
          'rotla' => {
            'schema_version' => 2,
            'ruleset' => 'en-second-printing',
            'mode' => 'long',
            'player_count' => 4,
            'map_manifest_version' => 1,
            'map_id' => MAP_ID,
            'minor_tableau' => [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]],
            'setup_journal' => [],
            'map_manifest' => {
              'map_id' => MAP_ID,
              'map_version' => 1,
              'projects' => [],
              'placements' => PIECE_ORIGINS.each_with_index.map do |origin, index|
                { 'copy_id' => format('long4-%02d', index + 1), 'origin' => origin, 'rotation' => 0 }
              end,
            },
          },
        }.freeze

        TILES = TrackTiles::TILES
        LOCATION_NAMES = {}.freeze
      end
    end
  end
end
