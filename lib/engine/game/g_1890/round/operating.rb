# frozen_string_literal: true

require_relative '../../../round/operating'
require_relative '../../../step/buy_train'

module Engine
  module Game
    module G1890
      module Round
        class Operating < Engine::Round::Operating
          def recalculate_order_when_merge_Kintetsu
            unsorted_corps = @entities.pop(@entities.size - @entity_index - 1)
            @log << "recalculate_order" 
            @entities.concat(@game.operating_order.select { |e| e.name == '近鉄' })
            @entities.concat(@game.operating_order.select { |e| unsorted_corps.include?(e) && e.name != '近鉄' })
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
