# frozen_string_literal: true

require_relative '../../../round/stock'

module Engine
  module Game
    module GRotLA
      module Round
        # RotLA applies the end-of-stock-round sold-out increase to both
        # Minor Companies and Major Companies. The engine default excludes
        # corporations whose type is :minor.
        class Stock < Engine::Round::Stock
          protected

          def finish_round
            return restart_initial_stock_round if @game.rotla_restart_initial_stock_round?

            super
          end

          def corporations_to_move_price
            @game.corporations.select(&:floated?)
          end

          def restart_initial_stock_round
            @game.rotla_reshuffle_minor_tableau!
            @entities.each(&:unpass!)
            @pass_order.clear
            @last_to_act = nil
            start_entity
          end
        end
      end
    end
  end
end
