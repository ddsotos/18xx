# frozen_string_literal: true

require_relative '../../../step/dividend'
require_relative '../../../step/half_pay'
require_relative '../../../step/minor_half_pay'

module Engine
  module Game
    module G1890
      module Step
        class Dividend < Engine::Step::Dividend
          include Engine::Step::HalfPay
          include Engine::Step::MinorHalfPay

          def dividend_types
            return [:half] if current_entity&.id == 'JR'

            super
          end

          def half(entity, revenue)
            return super unless entity.id == 'JR'

            shareholder_total = (revenue / 20) * 10
            {
              corporation: revenue - shareholder_total,
              per_share: payout_per_share(entity, shareholder_total),
            }
          end

          def share_price_change(entity, revenue = 0)
            if entity.id == '近鉄' && @game.kintetsu_special_operating? && !revenue.positive?
              return {}
            end

            super
          end

          def process_dividend(action)
            routes_for_kobe_rapid = routes.dup
            super
            @game.pay_kobe_rapid_revenue!(routes_for_kobe_rapid)
            return unless action.entity.id == '近鉄' && @game.kintetsu_special_operating?

            @game.finish_kintetsu_special_operating!
          end
        end
      end
    end
  end
end
