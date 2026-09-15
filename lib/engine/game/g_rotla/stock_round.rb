# frozen_string_literal: true

require_relative 'round/stock'
require_relative 'minor_tableau'
require_relative 'stock_round_steps'

module Engine
  module Game
    module GRotLA
      # Game-level Stock Round contract. The concrete RotLA Game includes this
      # module once its official fixed-map catalog is ready for registration.
      module StockRound
        def stock_round
          @rotla_stock_round_count = (@rotla_stock_round_count || 0) + 1
          Round::Stock.new(self, StockRoundSteps.steps, round_num: @rotla_stock_round_count)
        end

        def rotla_restart_initial_stock_round?
          @rotla_stock_round_count == 1 && corporations.none?(&:ipoed)
        end

        def rotla_reshuffle_minor_tableau!
          @rotla_minor_tableau = MinorTableau.shuffled(random_index: ->(limit) { rand % limit })
          @log << '-- No Minor Companies were founded; reshuffling and restarting the initial Stock Round --'
          @log << "Available Minor Companies: #{@rotla_minor_tableau.front_ids.join(', ')}"
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
