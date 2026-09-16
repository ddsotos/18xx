# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module GRotLA
      module Step
        class Dividend < Engine::Step::Dividend
          def share_price_change(entity, revenue)
            price = entity.share_price&.price
            return {} unless price
            return { share_direction: :left, share_times: 1 } if revenue.zero?
            return {} if revenue < price
            return { share_direction: :right, share_times: 1 } if revenue < (price * 2)

            { share_direction: :right, share_times: 2 }
          end

          def change_share_price(entity, payout)
            if payout[:share_direction]
              super
            elsif entity.share_price
              corporations = entity.share_price.corporations
              corporations.delete(entity)
              corporations << entity
            end
          end
        end
      end
    end
  end
end
