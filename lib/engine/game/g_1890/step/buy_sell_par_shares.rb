# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G1890
      module Step
        class BuySellParShares < Engine::Step::BuySellParShares
          def get_par_prices(entity, corporation)
            return super unless corporation.name == "JR"
            @game
            .stock_market
            .par_prices
            .select { |p| p.price * 2 <= available_cash(entity) && p.price == 100}#JRは100固定
 
          end

        end
      end
    end
  end
end
