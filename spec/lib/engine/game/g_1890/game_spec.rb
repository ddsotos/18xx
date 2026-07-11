# frozen_string_literal: true

require 'spec_helper'

module Engine
  describe Game::G1890::Game do
    let(:players) { %w[A B C] }
    subject(:game) { described_class.new(players) }

    describe 'scenario C setup' do
      it 'divides the initial player cash pool of 2520 yen equally' do
        expect(described_class::STARTING_CASH).to eq(
          2 => 1260,
          3 => 840,
          4 => 630,
          5 => 504,
          6 => 420,
          7 => 360,
        )
      end
    end

    describe 'initial auction' do
      it 'uses the companies in the scenario C prescribed order' do
        expect(game.round).to be_a(Round::Auction)
        expect(game.round.active_step.companies.map(&:name)).to eq(
          %w[有馬鉄道 神戸市電 阪堺電鉄 阪神国道軌道 京津鉄道 大阪市電 河南鉄道 大阪電気軌道 大阪鉄道 奈良電鉄 神戸電鉄],
        )
      end

      it 'changes Osaka City Tram face value to zero when a player buys it' do
        company = game.company_by_id('市電')

        game.after_buy_company(game.players.first, company, company.value)

        expect(company.value).to eq(0)
      end

      it 'discounts only Arima Railway by 5 after every player passes' do
        step = game.round.active_step
        arima, kobe_tram = step.companies.first(2)

        game.players.each do |player|
          step.process_pass(Action::Pass.new(player))
        end

        expect(arima.min_bid).to eq(15)
        expect(kobe_tram.min_bid).to eq(40)
      end
    end
  end
end
