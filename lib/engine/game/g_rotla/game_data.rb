# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # Four-player Long Game data from the English second-printing rulebook,
      # paper pp. 2-3, 7 and 16. The marked extra 3 and 6 are included for 4 players.
      module GameData
        STARTING_CASH = { 4 => 275 }.freeze

        MARKET = [
          %w[0c 10 20 30 40 50 60p 70p 80p 90p 100p 110p 120p 135p 150 165 180 200 220 245 270 300 330 360
             400 450 500],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: { minor: 2, major: 0 },
            tiles: [:yellow],
            operating_rounds: 2,
          },
          {
            name: '3',
            on: '3',
            train_limit: { minor: 2, major: 4 },
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '4',
            on: '4',
            train_limit: { minor: 2, major: 3 },
            tiles: %i[yellow green],
            operating_rounds: 2,
          },
          {
            name: '5',
            on: '5',
            train_limit: { minor: 1, major: 2 },
            tiles: %i[yellow green purple],
            operating_rounds: 2,
          },
          {
            name: '6',
            on: '6',
            train_limit: { minor: 1, major: 2 },
            tiles: %i[yellow green purple],
            operating_rounds: 2,
          },
          {
            name: '7',
            on: '7',
            train_limit: { minor: 1, major: 2 },
            tiles: %i[yellow green purple gray],
            operating_rounds: 2,
          },
        ].freeze

        TRAINS = [
          { name: '2', distance: 2, price: 100, rusts_on: '4', num: 7 },
          { name: '3', distance: 3, price: 200, rusts_on: '6', num: 6 },
          { name: '4', distance: 4, price: 300, rusts_on: '7', num: 4 },
          { name: '5', distance: 5, price: 450, num: 3 },
          { name: '6', distance: 6, price: 550, num: 3 },
          {
            name: '7',
            distance: 7,
            price: 750,
            num: 7,
            variants: [{ name: '∞', distance: 99, price: 1000 }],
          },
        ].freeze

        TRAIN_COUNTS = TRAINS.to_h { |train| [train[:name], train[:num]] }.freeze
      end
    end
  end
end
