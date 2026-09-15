# frozen_string_literal: true

require_relative '../../../step/issue_shares'

module Engine
  module Game
    module GRotLA
      module Step
        class IssueOrRedeem < Engine::Step::IssueShares
          def process_sell_shares(action)
            validate_single_share!(action)
            corporation = action.entity
            old_price = corporation.share_price
            super
            @game.stock_market.move_left(corporation)
            @game.log_share_price(corporation, old_price)
          end

          def process_buy_shares(action)
            validate_single_share!(action)
            super
          end

          private

          def validate_single_share!(action)
            corporation = action.entity
            bundle = action.bundle
            legal = corporation == current_entity && bundle&.corporation == corporation &&
                    bundle.shares.one? && !bundle.presidents_share && !bundle.partial? &&
                    bundle.percent == corporation.share_percent
            raise GameError, 'RotLA may issue or redeem exactly one ordinary share' unless legal
          end
        end
      end
    end
  end
end
