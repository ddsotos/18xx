# frozen_string_literal: true

require_relative '../../../step/token'

module Engine
  module Game
    module G1890
      module Step
        class Token < Engine::Step::Token
          KOBE_RAPID_PASSAGE_CHOICE = 'buy_kobe_rapid_passage'

          def actions(entity)
            actions = super
            return actions unless can_buy_kobe_rapid_passage?(entity)

            (actions | %w[choose pass])
          end

          def choice_name
            'Additional Token Actions'
          end

          def choices
            return {} unless can_buy_kobe_rapid_passage?(current_entity)

            price = kobe_rapid_passage_price(current_entity)
            {
              KOBE_RAPID_PASSAGE_CHOICE => "Buy Kobe Rapid passage for #{@game.format_currency(price)}",
            }
          end

          def process_choose(action)
            raise GameError, 'Illegal choice' unless action.choice == KOBE_RAPID_PASSAGE_CHOICE
            raise GameError, "#{action.entity.name} cannot buy Kobe Rapid passage" unless can_buy_kobe_rapid_passage?(action.entity)

            @game.buy_kobe_rapid_passage!(action.entity)
            pass!
          end

          def can_buy_kobe_rapid_passage?(entity)
            return false unless entity == current_entity
            return false unless @game.kobe_rapid_available?
            return false if @game.kobe_rapid_passage_bought?(entity)

            price = kobe_rapid_passage_price(entity)
            return false unless price
            return false if entity.cash < price

            kobe_city.blocks?(entity)
          end

          def kobe_rapid_passage_price(entity)
            entity.unplaced_tokens.find { |token| token.price.positive? }&.price
          end

          def kobe_city
            @game.hex_by_id('F5').tile.cities.first
          end
        end
      end
    end
  end
end
