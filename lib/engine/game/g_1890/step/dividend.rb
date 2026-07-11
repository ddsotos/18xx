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
        end
      end
    end
  end
end
