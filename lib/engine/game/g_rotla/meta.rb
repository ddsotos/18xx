# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module GRotLA
      module Meta
        include Game::Meta

        DEV_STAGE = :alpha
        GAME_TITLE = 'Railways of the Lost Atlas'
        GAME_DISPLAY_TITLE = 'Railways of the Lost Atlas'
        GAME_ALIASES = %w[RotLA].freeze
        GAME_DESIGNER = 'Kevin Delger and Jacob Schacht'
        GAME_LOCATION = 'The Lost Atlas'
        GAME_PUBLISHER = :asterisk_games
        GAME_INFO_URL = 'https://www.asterisk-games.com/railwaysofthelostatlas'
        GAME_RULES_URL = 'https://www.asterisk-games.com/rulebook'
        PLAYER_RANGE = [4, 4].freeze
      end
    end
  end
end
