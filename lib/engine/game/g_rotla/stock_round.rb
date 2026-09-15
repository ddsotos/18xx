# frozen_string_literal: true

require_relative 'round/stock'
require_relative 'stock_round_steps'

module Engine
  module Game
    module GRotLA
      # Game-level Stock Round contract. The concrete RotLA Game includes this
      # module once its official fixed-map catalog is ready for registration.
      module StockRound
        def stock_round
          Round::Stock.new(self, StockRoundSteps.steps)
        end

        # RotLA limits ownership to 60% per company but has no certificate cap.
        def cert_limit(_player = nil)
          Float::INFINITY
        end

        def show_game_cert_limit?
          false
        end
      end
    end
  end
end
