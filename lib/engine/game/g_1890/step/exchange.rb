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
            entity.close!
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

            @game.log << "merge_minor #{minor.name} "

            if minor.name == "大軌"
              merge_minor!(minor, corporation, source)
              corporation.floatable = true #Kintetsu floats when president share is bought
              initialCapital = corporation.par_price.price * 4
              @game.bank.spend(initialCapital, corporation)
              @game.log << "#{corporation.name} floats with #{initialCapital} (par_price *4)"

              hantetsu = @game.minors.find { |m| m.name == "阪鉄" }
              exchange_share(hantetsu, corporation, source)
              merge_minor!(hantetsu, corporation, source)
              @round.recalculate_order_when_merge_Kintetsu if @round.respond_to?(:recalculate_order_when_merge_Kintetsu)
              hantetsu_private = @game.companies.find { |c| c.sym == "阪鉄" }
              hantetsu_private.close!
            else
              exchange_share(minor, corporation, source)
              merge_minor!(minor, corporation, source)
            end

          end
        end
      end
    end
  end
end
