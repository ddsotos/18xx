# frozen_string_literal: true

require_relative 'step/adaptive_home'
require_relative 'step/founding_auction'
require_relative 'step/stock_trade'

module Engine
  module Game
    module GRotLA
      # Canonical Step order for Game#stock_round once the concrete Game exists.
      # FoundingAuction is initially non-blocking, AdaptiveHome blocks only while
      # its choice is pending, and StockTrade closes the ordinary player turn.
      module StockRoundSteps
        STEPS = [Step::FoundingAuction, Step::AdaptiveHome, Step::StockTrade].freeze

        def self.steps
          STEPS.dup
        end
      end
    end
  end
end
