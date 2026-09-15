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

          def corporations_to_move_price
            @game.corporations.select(&:floated?)
          end
        end
      end
    end
  end
end
