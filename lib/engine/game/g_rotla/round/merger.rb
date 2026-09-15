# frozen_string_literal: true

require_relative '../../../round/merger'

module Engine
  module Game
    module GRotLA
      module Round
        # Ability-neutral merger round used by the playable vertical slice.
        # Explicit consent and official-map connection checks remain separate
        # rule refinements; the round and its choices are replay-stable now.
        class Merger < Engine::Round::Merger
          def self.round_name
            'Merger Round'
          end

          def self.short_name
            'MR'
          end

          def select_entities
            @game.corporations.select { |corporation| corporation.type == :minor && corporation.floated? }.sort
          end

          def setup
            skip_steps
            next_entity! unless active_step || @entities.empty?
          end

          def after_process(_action)
            next_entity! unless active_step
          end

          def next_entity!
            return if @entities.empty? || @entity_index == @entities.size - 1

            next_entity_index!
            return next_entity! if @entities[@entity_index].closed?

            @steps.each(&:unpass!)
            @steps.each(&:setup)
            skip_steps
            next_entity! unless active_step
          end
        end
      end
    end
  end
end
