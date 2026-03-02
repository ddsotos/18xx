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
        end
      end
    end
  end
end
