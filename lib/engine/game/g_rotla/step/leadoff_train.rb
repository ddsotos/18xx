# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module GRotLA
      module Step
        # Offers a newly founded Minor Company one optional train purchase at
        # the start of its first operation. This is deliberately separate from
        # the normal BuyTrain step: only depot/pool trains at face value and
        # corporate cash are legal here.
        class LeadoffTrain < Engine::Step::BuyTrain
          def description
            'Buy Leadoff Train'
          end

          def pass_description
            'Skip Leadoff Train'
          end

          def actions(entity)
            return [] unless eligible?(entity)

            actions = ['pass']
            actions.unshift('buy_train') if can_buy_train?(entity)
            actions
          end

          def can_entity_buy_train?(entity)
            eligible?(entity)
          end

          def can_buy_train?(entity = nil, _shell = nil)
            entity ||= current_entity
            eligible?(entity) && room?(entity) && buyable_trains(entity).any?
          end

          def buyable_trains(entity)
            return [] unless eligible?(entity) && room?(entity)

            @depot.depot_trains.select do |train|
              train.buyable(allow_obsolete_buys: @game.class::ALLOW_OBSOLETE_TRAIN_BUY) &&
                affordable_variants(train, entity).any?
            end
          end

          def buyable_train_variants(train, entity)
            return [] unless buyable_trains(entity).include?(train)

            affordable_variants(train, entity)
          end

          def spend_minmax(entity, train)
            price = train.price
            return [price, price] if eligible?(entity) && train.from_depot? && entity.cash >= price

            [0, 0]
          end

          def president_may_contribute?(_entity, _shell = nil)
            false
          end

          def must_buy_train?(_entity)
            false
          end

          def process_buy_train(action)
            entity = action.entity
            train = action.train
            variant = action.variant || train.name
            validate_purchase!(action, entity, train, variant)

            source = train.owner
            train.variant = variant
            @log << "#{entity.name} buys a #{train.name} leadoff train for " \
                    "#{@game.format_currency(action.price)} from #{source.name}"
            @game.buy_train(entity, train, action.price)
            @game.phase.buying_train!(entity, train, source)
            pass!
          end

          private

          def eligible?(entity)
            return false unless entity == current_entity
            return false unless entity&.corporation? && entity.type == :minor

            !corporation_operated?(entity)
          end

          def corporation_operated?(corporation)
            if @game.respond_to?(:rotla_corporation_operated?)
              @game.rotla_corporation_operated?(corporation)
            else
              corporation.operated?
            end
          end

          def affordable_variants(train, entity)
            train.variants.values.select { |variant| variant[:buyable] && variant[:price] <= entity.cash }
          end

          def validate_purchase!(action, entity, train, variant_name)
            raise GameError, 'Only the operating Minor Company may buy a leadoff train' unless eligible?(entity)
            raise GameError, 'The Minor Company has no room for a leadoff train' unless room?(entity)
            raise GameError, 'A leadoff train must come from the depot or bank pool' unless train&.from_depot?
            raise GameError, 'This train is not currently available' unless @depot.depot_trains.include?(train)
            raise GameError, 'Leadoff train purchases do not allow exchanges or modifiers' if purchase_modifier?(action)

            variant = train.variants[variant_name]
            raise GameError, "Unknown train variant #{variant_name}" unless variant
            raise GameError, 'This train variant is not buyable' unless variant[:buyable]
            raise GameError, 'A leadoff train must be bought at face value' unless action.price == variant[:price]
            raise GameError, 'The Minor Company cannot afford this leadoff train' if entity.cash < action.price
          end

          def purchase_modifier?(action)
            action.exchange || action.shell || action.slots || action.extra_due || action.warranties
          end
        end
      end
    end
  end
end
