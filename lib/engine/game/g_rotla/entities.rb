# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # Entity identities and financial structure for the four-player Long Game.
      # The provisional map supplies stable homes; the official catalog may
      # replace only this coordinate list without changing company identities.
      module Entities
        MINOR_SHARES = [40, 20, 20, 20].freeze
        MAJOR_SHARES = ([20] + Array.new(8, 10)).freeze
        MINOR_TOKENS = [0].freeze
        MAJOR_TOKENS = [0, 0, 60, 80].freeze
        ADAPTIVE_ID = 'ADA'.freeze
        HOME_COORDINATES = %w[A1 C3 E5 G7 A5 C7 E9 G11 A9 C11 E13].freeze

        MINOR_COMPANIES = [
          { sym: 'SPA', name: 'Spacious', ability_id: :spacious, color: '#8bcf7b', text_color: 'black' },
          { sym: 'ADA', name: 'Adaptive', ability_id: :adaptive, color: '#7655a6' },
          { sym: 'BRI', name: 'Bridging', ability_id: :bridging, color: '#45bdb3', text_color: 'black' },
          { sym: 'OVN', name: 'Overnight', ability_id: :overnight, color: '#282421' },
          { sym: 'TUN', name: 'Tunneling', ability_id: :tunneling, color: '#777777' },
          { sym: 'RES', name: 'Resourceful', ability_id: :resourceful, color: '#eea45b', text_color: 'black' },
          { sym: 'EM', name: 'Eastern Mining', ability_id: :eastern_mining, color: '#aa6944' },
          { sym: 'AGR', name: 'Agricultural', ability_id: :agricultural, color: '#438e67' },
          { sym: 'NP', name: 'Northern Port', ability_id: :northern_port, color: '#326e9b' },
          { sym: 'XPN', name: 'Expansive', ability_id: :expansive, color: '#e94e86' },
          { sym: 'XPR', name: 'Express', ability_id: :express, color: '#b62f43' },
          { sym: 'SUB', name: 'Suburban', ability_id: :suburban, color: '#ef9c91', text_color: 'black' },
        ].map.with_index do |company, index|
          company.merge(
            logo: 'rotla/minor',
            type: 'minor',
            shares: MINOR_SHARES,
            tokens: MINOR_TOKENS,
            float_percent: 40,
            max_ownership_percent: 60,
            capitalization: :incremental,
            always_market_price: true,
            coordinates: company[:sym] == ADAPTIVE_ID ? nil : HOME_COORDINATES[index - (index > 1 ? 1 : 0)],
          ).freeze
        end.freeze

        MAJOR_CORPORATIONS = [
          { sym: 'C', name: 'Consortium', color: '#e43b45' },
          { sym: 'U', name: 'Union', color: '#ec813d', text_color: 'black' },
          { sym: 'S', name: 'System', color: '#e9b844', text_color: 'black' },
          { sym: 'I', name: 'International', color: '#65b7cf', text_color: 'black' },
          { sym: 'F', name: 'Federation', color: '#69ad45', text_color: 'black' },
          { sym: 'E', name: 'Experiment', color: '#8f4f9f' },
        ].map do |corporation|
          corporation.merge(
            logo: 'rotla/major',
            type: 'major',
            shares: MAJOR_SHARES,
            tokens: MAJOR_TOKENS,
            float_percent: 20,
            max_ownership_percent: 60,
            capitalization: :incremental,
            always_market_price: true,
          ).freeze
        end.freeze

        CORPORATIONS = (MINOR_COMPANIES + MAJOR_CORPORATIONS).freeze
        SHORT_GAME_EXCLUSIONS = %w[ADA OVN BRI SPA].freeze
        ABILITY_BY_MINOR = MINOR_COMPANIES.to_h { |company| [company[:sym], company[:ability_id]] }.freeze
      end
    end
  end
end
