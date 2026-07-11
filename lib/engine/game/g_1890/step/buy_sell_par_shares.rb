# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G1890
      module Step
        class BuySellParShares < Engine::Step::BuySellParShares
          def can_sell?(entity, bundle)
            return false if attached_share_locked?(bundle)

            super
          end

          def attached_share_locked?(bundle)
            return false unless bundle && %w[京阪 阪神].include?(bundle.corporation.id)

            bundle.corporation.presidents_share.owner == bundle.corporation
          end

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
