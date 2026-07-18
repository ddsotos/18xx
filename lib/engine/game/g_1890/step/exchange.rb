# frozen_string_literal: true

require_relative '../../../step/exchange'
require_relative 'minor_exchange'

module Engine
  module Game
    module G1890
      module Step
        class Exchange < Engine::Step::Exchange
          include MinorExchange

          KOBE_ELECTRIC_LATECOMERIZE_CHOICE = 'kobe_electric_latecomerize'

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

          def actions(entity)
            actions = []
            actions.concat(ACTIONS) if can_exchange?(entity)
            actions << 'choose' if can_latecomerize_kobe_electric?(entity)
            actions << 'choose_ability' if can_latecomerize_kobe_electric_ability?(entity)
            return [] if actions.empty?

            actions + %w[pass]
          end

          def blocks?
            can_exchange?(current_entity) || can_latecomerize_kobe_electric?(current_entity)
          end

          def choice_name
            'Kobe Electric'
          end

          def choices
            return {} unless can_latecomerize_kobe_electric?(current_entity)

            {
              KOBE_ELECTRIC_LATECOMERIZE_CHOICE => 'Declare Kobe Electric as a latecomer company',
            }
          end

          def choices_ability(entity)
            return {} unless can_latecomerize_kobe_electric_ability?(entity)

            {
              KOBE_ELECTRIC_LATECOMERIZE_CHOICE => 'Declare Kobe Electric as a latecomer company',
            }
          end

          def can_exchange?(entity, bundle = nil)
            entity = exchange_minor_entity(entity)
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
                @game.phase.available?('3') && kintetsu.floatable
              else
                false
              end
            return false unless allowed
            return bundle.corporation == kintetsu if bundle

            entity.id == '大軌' || @game.reserved_kintetsu_shares(kintetsu).any?
          end

          def process_buy_shares(action)
            entity = exchange_minor_entity(action.entity)
            raise GameError, "Cannot exchange #{action.entity.id} for #{action.bundle.corporation.id}" unless can_exchange?(entity, action.bundle)

            @game.exchange_minor(entity, action.bundle)
            # @round.players_history[company.owner][bundle.corporation] << action if @round.respond_to?(:players_history)
          end

          def process_choose(action)
            raise GameError, 'Illegal choice' unless action.choice == KOBE_ELECTRIC_LATECOMERIZE_CHOICE
            raise GameError, "#{action.entity.id} cannot latecomerize Kobe Electric" unless
              can_latecomerize_kobe_electric?(action.entity)

            @game.latecomerize_kobe_electric!
            pass!
          end

          def process_choose_ability(action)
            raise GameError, 'Illegal choice' unless action.choice == KOBE_ELECTRIC_LATECOMERIZE_CHOICE
            raise GameError, "#{action.entity.id} cannot latecomerize Kobe Electric" unless
              can_latecomerize_kobe_electric_ability?(action.entity)

            @game.latecomerize_kobe_electric!
          end

          def process_pass(_action)
            pass!
          end

          def exchange_minor_entity(entity)
            return entity unless entity.company? && entity.type == :minor

            @game.minor_by_id(entity.id) || entity
          end

          def can_latecomerize_kobe_electric?(entity)
            entity = exchange_minor_entity(entity)
            kobe = @game.minor_by_id('神戸')
            company = @game.company_by_id('神戸')
            return false unless kobe&.owner && company&.owner && !kobe.closed?
            return false if @game.kobe_electric_latecomerized?(company)

            entity == kobe
          end

          def can_latecomerize_kobe_electric_ability?(entity)
            return false unless entity&.company? && entity.id == '神戸'

            kobe = @game.minor_by_id('神戸')
            company = @game.company_by_id('神戸')
            return false unless kobe&.owner && company&.owner && !kobe.closed?
            return false if @game.kobe_electric_latecomerized?(company)

            entity.owner == kobe.owner
          end

        end
      end
    end
  end
end
