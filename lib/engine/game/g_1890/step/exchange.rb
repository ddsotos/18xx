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

          def can_exchange?(entity, bundle = nil)
            return super unless entity.minor?
            return false unless entity.owner && !entity.closed?

            kintetsu = @game.corporation_by_id('近鉄')
            allowed =
              case entity.id
              when '大軌'
                @game.phase.available?('2')
              when '河南'
                @game.phase.available?('2') && kintetsu.floatable
              when '奈良'
                @game.phase.available?('4') && kintetsu.floatable
              else
                false
              end
            return false unless allowed
            return bundle.corporation == kintetsu if bundle

            entity.id == '大軌' || @game.reserved_kintetsu_shares(kintetsu).any?
          end

          def process_buy_shares(action)
            entity = action.entity
            @game.log << "can_exchange? #{entity.name} "
            @game.exchange_minor(entity, action.bundle)
            # @round.players_history[company.owner][bundle.corporation] << action if @round.respond_to?(:players_history)
          end

          def process_pass(_action)
            @game.minors.dup.each do |minor|
              next unless minor&.owner == current_entity

              merge_minor!(minor, nil, @game.bank)
            end

            super
          end

        end
      end
    end
  end
end
