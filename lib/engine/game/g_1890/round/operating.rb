# frozen_string_literal: true

require_relative '../../../round/operating'
require_relative '../../../step/buy_train'

module Engine
  module Game
    module G1890
      module Round
        class Operating < Engine::Round::Operating
          def start_operating
            entity = @entities[@entity_index]
            if entity&.id == 'メトロ'
              @game.release_osaka_city_tram_blocks!
              @game.activate_osaka_metro_special_tile_lay!
            end

            super
          end

          def recalculate_order_when_merge_Kintetsu
            remaining_entities = @entities.pop(@entities.size - @entity_index)
            kintetsu = @game.corporation_by_id('近鉄')
            remaining_entities.delete(kintetsu)
            @entities << kintetsu
            @entities.concat(remaining_entities)
            @log << '近鉄 begins its special operation immediately'

            @steps.each(&:unpass!)
            @steps.each(&:setup)
            start_operating
          end
          def after_process(action)
            return if action.type == 'message'
            @game.log << "action.entity.corporation: #{action.entity} current_operator:#{@current_operator}"
            @current_operator_acted = true if action.entity == @current_operator
            @current_operator_acted = true if action.entity.corporation == @current_operator

            if active_step
              entity = @entities[@entity_index]
              return if entity.owner&.player? || entity.receivership?
            end

            after_end_of_turn(@current_operator)

            next_entity! unless @game.finished
          end
        end
      end
    end
  end
end
