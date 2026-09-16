# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # Physical track-tile inventory transcribed from the component illustration
      # in the English second-printing rulebook (paper p. 2 / PDF p. 3).
      #
      # The printed tiles do not carry conventional 18xx tile numbers, so these
      # IDs are stable implementation identifiers. Geometry is deliberately
      # descriptive rather than Engine tile DSL; TrackTiles holds the verified
      # edge pairings and upgrade-family symbols that feed Map::TILES.
      module TrackTileManifest
        SOURCE = {
          file: 'Railways-EN-2nd-Rulebook.pdf',
          edition: 'English second printing',
          paper_page: 2,
          pdf_page: 3,
          stated_total: 135,
        }.freeze

        def self.tile(id, color, count, geometry, group, image, x, y)
          {
            id: id,
            color: color,
            count: count,
            geometry: geometry,
            source_group: group,
            source_image: image,
            source_top: [x, y].freeze,
          }.freeze
        end

        TILES = [
          tile('RLA-Y01', :yellow, 14, :broad_curve, 1, 262, 76.676, 452.437),
          tile('RLA-Y02', :yellow, 7, :city_straight, 2, 340, 114.091, 452.437),
          tile('RLA-Y03', :yellow, 7, :city_straight, 3, 319, 151.221, 452.437),
          tile('RLA-Y04', :yellow, 1, :city_straight, 4, 68, 180.922, 452.437),
          tile('RLA-Y05', :yellow, 1, :city_straight, 5, 66, 214.090, 452.437),
          tile('RLA-Y06', :yellow, 1, :city_sharp_curve, 6, 64, 247.257, 452.437),
          tile('RLA-Y07', :yellow, 13, :straight, 7, 223, 66.353, 413.503),
          tile('RLA-Y08', :yellow, 6, :sharp_curve, 8, 361, 99.520, 413.503),
          tile('RLA-Y09', :yellow, 5, :city_sharp_curve, 9, 379, 132.687, 413.503),

          tile('RLA-G01', :green, 4, :two_paths, 10, 211, 165.855, 413.503),
          tile('RLA-G02', :green, 4, :two_paths, 11, 199, 199.022, 413.503),
          tile('RLA-G03', :green, 2, :two_paths, 12, 193, 232.189, 413.503),
          tile('RLA-G04', :green, 1, :two_paths, 13, 48, 265.357, 413.503),
          tile('RLA-G05', :green, 1, :two_paths, 14, 38, 49.769, 386.021),
          tile('RLA-G06', :green, 1, :two_paths, 15, 36, 82.936, 386.021),
          tile('RLA-G07', :green, 1, :two_paths, 16, 42, 116.104, 386.021),
          tile('RLA-G08', :green, 1, :two_paths, 17, 40, 149.271, 386.021),
          tile('RLA-G09', :green, 1, :two_paths, 18, 32, 182.438, 386.021),
          tile('RLA-G10', :green, 1, :two_paths, 19, 30, 215.606, 386.021),
          tile('RLA-G11', :green, 1, :two_paths, 20, 28, 248.773, 386.021),
          tile('RLA-G12', :green, 1, :two_paths, 21, 24, 281.940, 386.021),
          tile('RLA-G13', :green, 5, :city_two_slot, 22, 142, 103.706, 351.314),
          tile('RLA-G14', :green, 4, :city_two_slot, 23, 304, 69.864, 352.472),
          tile('RLA-G15', :green, 4, :city_two_slot, 24, 130, 135.811, 352.472),
          tile('RLA-G16', :green, 1, :crossing_paths, 25, 34, 166.177, 355.948),
          tile('RLA-G17', :green, 1, :parallel_curves, 26, 26, 199.150, 355.948),
          tile('RLA-G18', :green, 1, :crossing_paths, 27, 46, 232.123, 355.948),
          tile('RLA-G19', :green, 1, :crossing_paths, 28, 44, 265.097, 355.948),
          tile('RLA-G20', :green, 2, :city_two_slot, 32, 124, 152.356, 323.703),
          tile('RLA-G21', :green, 2, :city_two_slot, 33, 118, 185.951, 323.703),
          tile('RLA-G22', :green, 1, :city_two_slot, 34, 54, 217.808, 324.862),
          tile('RLA-G23', :green, 1, :city_two_slot_special, 35, 58, 249.665, 324.862),
          tile('RLA-G24', :green, 1, :city_two_slot_special, 36, 56, 281.940, 324.862),

          tile('RLA-P01', :purple, 2, :multi_path, 29, 163, 51.571, 323.703),
          tile('RLA-P02', :purple, 2, :multi_path, 30, 187, 85.166, 323.703),
          tile('RLA-P03', :purple, 2, :multi_path, 31, 169, 118.761, 323.703),
          tile('RLA-P04', :purple, 2, :multi_path, 37, 157, 67.996, 293.842),
          tile('RLA-P05', :purple, 2, :multi_path, 38, 175, 102.088, 293.842),
          tile('RLA-P06', :purple, 2, :multi_path, 39, 181, 136.179, 293.842),
          tile('RLA-P07', :purple, 1, :multi_path, 40, 18, 168.533, 295.001),
          tile('RLA-P08', :purple, 1, :multi_path, 41, 20, 200.886, 295.001),
          tile('RLA-P09', :purple, 1, :multi_path, 42, 14, 233.240, 295.001),
          tile('RLA-P10', :purple, 1, :multi_path, 43, 16, 265.593, 295.001),
          tile('RLA-P11', :purple, 6, :city_two_slot, 44, 100, 53.888, 259.642),
          tile('RLA-P12', :purple, 2, :city_three_slot, 46, 85, 85.725, 261.964),
          tile('RLA-P13', :purple, 1, :city_three_slot_special, 47, 50, 117.848, 263.123),
          tile('RLA-P14', :purple, 1, :city_four_slot_special, 48, 52, 149.971, 263.123),
          tile('RLA-P15', :purple, 1, :crossing_paths, 49, 22, 182.095, 263.123),

          tile('RLA-X01', :gray, 3, :city_two_slot, 45, 91, 217.694, 260.805),
          tile('RLA-X02', :gray, 1, :city_three_slot, 50, 60, 249.817, 263.123),
          tile('RLA-X03', :gray, 1, :city_three_slot_special, 51, 62, 281.940, 263.123),

          tile('RLA-B01', :blue, 2, :bridge_broad_curve, 52, 73, 134.779, 231.178),
          tile('RLA-B02', :blue, 2, :bridge_straight, 53, 79, 167.537, 231.178),
          tile('RLA-B03', :blue, 1, :bridge_sharp_curve, 54, 70, 198.558, 231.178),
        ].freeze

        TOTAL_COUNT = TILES.sum { |tile_data| tile_data[:count] }
        COLOR_COUNTS = TILES.group_by { |tile_data| tile_data[:color] }
                            .transform_values { |tiles| tiles.sum { |tile_data| tile_data[:count] } }
                            .freeze
      end
    end
  end
end
