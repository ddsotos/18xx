# frozen_string_literal: true

require './spec/spec_helper'
require 'view/game/pass'

module View
  module Game
    describe Pass do
      describe '#render' do
        it 'shows auto pass for the current player in a hotseat game' do
          round = double(show_auto?: true)
          game = double(round: round, active_players_id: ['player-2'])
          component = described_class.new(
            nil,
            actions: ['pass'],
            game: game,
            game_data: { mode: :hotseat },
            user: { 'id' => 'player-1' },
          )
          allow(component).to receive(:h).and_return('')

          component.render

          expect(component).to have_received(:h).with(PassAutoButton)
        end

        it 'does not show auto pass to an inactive player in an online game' do
          round = double(show_auto?: true)
          game = double(round: round, active_players_id: ['player-2'])
          component = described_class.new(
            nil,
            actions: ['pass'],
            game: game,
            game_data: { mode: :multi },
            user: { 'id' => 'player-1' },
          )
          allow(component).to receive(:h).and_return('')

          component.render

          expect(component).not_to have_received(:h).with(PassAutoButton)
        end
      end
    end
  end
end
