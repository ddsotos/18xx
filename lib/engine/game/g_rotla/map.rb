# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # A deterministic four-player development map. It deliberately keeps the
      # physical-copy boundary and saved manifest used by the future verified
      # map, so replacing the provisional geometry does not affect round code.
      module Map
        MAP_ID = 'long4-playable-v0'
        PIECE_ORIGINS = 3.times.flat_map do |row|
          11.times.map { |column| [column * 2, row * 2].freeze }
        end.freeze

        COMPANY_HOME_COUNT = 11

        CITY_CODE = 'city=revenue:yellow_20|green_30|purple_40|gray_50,slots:3;' \
                    'path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;' \
                    'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0'

        MAP_CATALOG = PIECE_ORIGINS.each_index.to_h do |index|
          copy_id = format('long4-%02d', index + 1)
          first_type = index < COMPANY_HOME_COUNT ? 'company' : 'basic'
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
              'projects' => [
                { 'project_copy_id' => 'capital-01', 'target_city_id' => 'B2', 'effect_type' => 'capital' },
                { 'project_copy_id' => 'capital-02', 'target_city_id' => 'D4', 'effect_type' => 'capital' },
                { 'project_copy_id' => 'capital-03', 'target_city_id' => 'F6', 'effect_type' => 'capital' },
              ],
              'placements' => PIECE_ORIGINS.each_with_index.map do |origin, index|
                { 'copy_id' => format('long4-%02d', index + 1), 'origin' => origin, 'rotation' => 0 }
              end,
            },
          },
        }.freeze

        TILES = {}.freeze
        LOCATION_NAMES = {}.freeze
      end
    end
  end
end
