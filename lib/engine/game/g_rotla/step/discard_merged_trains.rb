# frozen_string_literal: true

require_relative '../../../step/discard_train'

module Engine
  module Game
    module GRotLA
      module Step
        # A merger may temporarily create a Major above its train limit. Keep the
        # Merger Round on that Major until its president discards enough trains.
        class DiscardMergedTrains < Engine::Step::DiscardTrain
          def round_state
            { pending_merged_corporation: nil }
          end

          def description
            'Discard Excess Trains After Merger'
          end

          def active?
            !pending_corporation.nil?
          end

          def active_entities
            active? ? [pending_corporation] : []
          end

          def actions(entity)
            entity == pending_corporation ? ACTIONS : []
          end

          def process_discard_train(action)
            corporation = pending_corporation
            unless action.entity == corporation && corporation.trains.include?(action.train)
              raise GameError, 'That train cannot be discarded for this merger'
            end
            unless @game.num_corp_trains(corporation) > @game.train_limit(corporation)
              raise GameError, "#{corporation.name} is not above its train limit"
            end

            super
            return if @game.num_corp_trains(corporation) > @game.train_limit(corporation)

            @round.pending_merged_corporation = nil
            pass!
          end

          private

          def pending_corporation
            @round.pending_merged_corporation
          end
        end
      end
    end
  end
end
