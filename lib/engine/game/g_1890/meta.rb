# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G1890
      module Meta
        include Game::Meta

        DEV_STAGE = :beta

        GAME_DISPLAY_TITLE = '1890'

        GAME_DESIGNER = 'Shinichi Takasaki(高崎　真一)'
        GAME_INFO_URL = 'https://boardgamegeek.com/boardgame/38335/1890'
        GAME_LOCATION = '大阪, Japan'
        GAME_PUBLISHER = :grand_trunk_games#'高崎工房/サクラ会'
        GAME_RULES_URL = 'https://boardgamegeek.com/filepage/90922/rules'

        PLAYER_RANGE = [2, 7].freeze
        OPTIONAL_RULES = [
          {
            sym: :beginner_game,
            short_name: 'Beginner Game',
            desc: 'Simpler privates, more tiles available',
          },
          {
            sym: :hanshin_tigers,
            short_name: 'C10.12 Hanshin Tigers',
            desc: 'Replace the standard Nishinomiya bonus with a die roll',
          },
        ].freeze
      end
    end
  end
end

