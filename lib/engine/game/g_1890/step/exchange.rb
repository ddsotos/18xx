# frozen_string_literal: true

require_relative '../../../step/exchange'
require_relative 'minor_exchange'

module Engine
  module Game
    module G1890
      module Step
        class Exchange < Engine::Step::Exchange
          include MinorExchange

          def round_state
            super.merge(
              {
                major: nil,
                minor: nil,
                optional_trains: [],
                corporations_removing_tokens: nil,
                optional_forts: [],
              }
            )
          end

          def bought?
            @round.current_actions.any? do |action|
              Engine::Step::BuySellParShares::PURCHASE_ACTIONS.include?(action.class)
            end
          end

          def can_exchange?(entity, _bundle = nil)
            super
          end

          def process_buy_shares(action)
            entity = action.entity
            @game.log << "can_exchange? #{entity.name} "
            minor = @game.minors.find { |m| m.name == entity.sym }
            exchange_minor(minor, action.bundle)
            # @round.players_history[company.owner][bundle.corporation] << action if @round.respond_to?(:players_history)
          end

          def process_pass(_action)
            @game.minors.dup.each do |minor|
              next unless minor&.owner == current_entity

              merge_minor!(minor, nil, @game.bank)
            end

            super
          end

          def exchange_minor(minor, bundle)
            corporation = bundle.corporation
            source = bundle.owner
            # unless can_gain?(minor.owner, bundle, exchange: true)
            #   raise GameError, "#{minor.name} cannot be exchanged for #{corporation.name}"
            # end

            # exchange_share(minor, corporation, source)
            @game.log << "merge_minor #{minor.name} "

            merge_minor!(minor, corporation, source)

            corporation.floatable = true #Kintetsu floats when president share is bought
            initialCapital = corporation.par_price.price * 4
            @game.bank.spend(initialCapital, corporation)
            @game.log << "#{corporation.name} floats with #{initialCapital} (par_price *4)"

            hantetsu = @game.minors.find { |m| m.name == "阪鉄" }
            merge_minor!(hantetsu, corporation, source)
            # @game.share_pool.buy_shares(hantetsu.owner,
            #                             bundle,
            #                             silent: false)


            @round.recalculate_order_when_merge_Kintetsu if @round.respond_to?(:recalculate_order_when_merge_Kintetsu)

          end
        end
      end
    end
  end
end
