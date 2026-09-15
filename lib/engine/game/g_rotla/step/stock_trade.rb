# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module GRotLA
      module Step
        # Handles the ordinary share transaction portion of a RotLA stock turn.
        #
        # A player may sell any number of legal bundles and then buy at most one
        # ordinary share. Buying ends the turn immediately. Founding remains in
        # FoundingAuction; this step intentionally offers no Par action.
        class StockTrade < Engine::Step::BuySellParShares
          MARKET_LIMIT = 50
          OWNERSHIP_LIMIT = 60

          def description
            'Sell then Buy Shares'
          end

          def round_state
            super.merge(rotla_sold_corporations: [])
          end

          def setup
            super
            @round.rotla_sold_corporations = []
          end

          def actions(entity)
            return [] unless entity == current_entity

            actions = []
            actions << 'sell_shares' if can_sell_any?(entity)
            actions << 'buy_shares' if can_buy_any?(entity)
            actions << 'pass'
            actions
          end

          def can_buy?(entity, bundle)
            return false unless valid_actor?(entity)
            return false unless ordinary_share_purchase?(bundle)
            return false if bought?

            corporation = bundle.corporation
            return false if @round.players_sold[entity][corporation]
            return false if entity.percent_of(corporation) + bundle.percent > OWNERSHIP_LIMIT
            return false if entity.cash < share_value(bundle)

            can_gain?(entity, bundle)
          end

          def can_buy_any?(entity)
            @game.corporations.any? do |corporation|
              (corporation.treasury_shares + @game.share_pool.shares_of(corporation)).any? do |share|
                can_buy?(entity, share.to_bundle)
              end
            end
          end

          def can_sell?(entity, bundle)
            return false unless valid_actor?(entity)
            return false unless complete_owned_bundle?(entity, bundle)
            return false if bought?

            corporation = bundle.corporation
            return false unless corporation_operated?(corporation)
            return false if @game.share_pool.percent_of(corporation) + bundle.percent > MARKET_LIMIT

            bundle.can_dump?(entity)
          end

          # RotLA has an ownership-per-company limit, but no certificate limit.
          def can_gain?(entity, bundle, exchange: false)
            return false unless entity && bundle
            return false if exchange

            bundle.corporation.holding_ok?(entity, bundle.common_percent)
          end

          def must_sell?(_entity)
            false
          end

          def process_buy_shares(action)
            bundle = action.bundle
            validate_buy_action!(action, bundle)

            corporation = bundle.corporation
            receiver = bundle.owner == corporation ? corporation : @game.bank
            price = share_value(bundle)
            @game.share_pool.transfer_shares(
              bundle,
              action.entity,
              spender: action.entity,
              receiver: receiver,
              price: price,
            )
            @round.players_bought[action.entity][corporation] += bundle.percent
            track_action(action, corporation)
            @log << "#{action.entity.name} buys a #{bundle.percent}% share of #{corporation.name} " \
                    "for #{@game.format_currency(price)}"

            finish_stock_turn!
          end

          def process_sell_shares(action)
            bundle = action.bundle
            validate_sell_action!(action, bundle)

            corporation = bundle.corporation
            sale_price = bundle.price
            @game.share_pool.transfer_shares(
              bundle,
              @game.share_pool,
              spender: @game.bank,
              receiver: action.entity,
              price: sale_price,
            )
            @round.players_sold[action.entity][corporation] = :now
            @round.rotla_sold_corporations << corporation unless @round.rotla_sold_corporations.include?(corporation)
            track_action(action, corporation)
            @log << "#{action.entity.name} sells #{bundle.percent}% of #{corporation.name} " \
                    "for #{@game.format_currency(sale_price)}"
          end

          def process_pass(action)
            raise GameError, 'Only the current player may finish the stock turn' unless valid_actor?(action.entity)

            log_pass(action.entity)
            finish_stock_turn!
          end

          private

          def valid_actor?(entity)
            entity == current_entity && entity&.player?
          end

          def ordinary_share_purchase?(bundle)
            return false unless bundle
            return false unless bundle.buyable
            return false unless bundle.shares.one? && !bundle.partial?
            return false if bundle.presidents_share || bundle.share_price

            corporation = bundle.corporation
            return false unless corporation.ipoed && corporation.share_price
            return false unless bundle.percent == corporation.share_percent

            [corporation, @game.share_pool].include?(bundle.owner)
          end

          def complete_owned_bundle?(entity, bundle)
            return false unless bundle
            return false if bundle.partial? || bundle.share_price
            return false unless bundle.owner == entity

            bundle.shares.all? { |share| share.owner == entity }
          end

          def corporation_operated?(corporation)
            if @game.respond_to?(:rotla_corporation_operated?)
              @game.rotla_corporation_operated?(corporation)
            else
              corporation.operated?
            end
          end

          def share_value(bundle)
            (bundle.corporation.share_price.price * bundle.num_shares(ceil: false)).ceil
          end

          def validate_buy_action!(action, bundle)
            raise GameError, 'Only the current player may buy shares' unless valid_actor?(action.entity)
            if action.swap || action.purchase_for || action.borrow_from || action.total_price || action.discounter
              raise GameError, 'RotLA ordinary share purchases do not allow modifiers'
            end
            raise GameError, 'Cannot buy this share' unless can_buy?(action.entity, bundle)
          end

          def validate_sell_action!(action, bundle)
            raise GameError, 'Only the current player may sell shares' unless valid_actor?(action.entity)
            raise GameError, 'RotLA ordinary share sales do not allow swaps' if action.swap
            raise GameError, 'Cannot sell these shares' unless can_sell?(action.entity, bundle)
          end

          def finish_stock_turn!
            @round.rotla_sold_corporations.each do |corporation|
              old_price = corporation.share_price
              @game.stock_market.move_down(corporation)
              @game.log_share_price(corporation, old_price) if @game.respond_to?(:log_share_price)
            end
            @round.rotla_sold_corporations = []
            pass!
          end
        end
      end
    end
  end
end
