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

      it 'uses the prescribed train quantities' do
        quantities = described_class::TRAINS.to_h { |train| [train[:name], train[:num]] }

        expect(quantities).to eq(
          '2' => 9,
          '2-2' => 3,
          '3' => 5,
          '3-3' => 2,
          '4' => 4,
          '5' => 3,
          '6' => 2,
          'D' => 6,
        )
      end

      it 'creates an operating minor for each minor certificate' do
        expect(game.minors.map(&:id)).to eq(
          %w[河南 大軌 阪鉄 奈良 神戸],
        )
      end

      it 'uses the prescribed minor, public company, and JR train limits' do
        expect(described_class::PHASES.map { |phase| phase[:train_limit] }).to eq(
          [
            { minor: 2, major: 4, national: 6 },
            { minor: 2, major: 4, national: 6 },
            { minor: 1, major: 3, national: 4 },
            { minor: 1, major: 2, national: 3 },
            { minor: 1, major: 2, national: 3 },
            { minor: 1, major: 2, national: 3 },
          ],
        )

        expect(game.train_limit(game.minors.first)).to eq(2)
        expect(game.train_limit(game.corporation_by_id('南海'))).to eq(4)
        expect(game.train_limit(game.corporation_by_id('JR'))).to eq(6)
      end

      it 'floats and places a minor home token only when its certificate is bought' do
        company = game.company_by_id('河南')
        minor = game.minor_by_id('河南')
        player = game.players.first

        expect(minor).not_to be_floated
        expect(minor.tokens.first.used).to be(false)

        company.owner = player
        player.companies << company
        game.after_buy_company(player, company, company.value)

        expect(minor.owner).to eq(player)
        expect(minor).to be_floated
        expect(minor.cash).to eq(100)
        expect(minor.tokens.first.used).to be(true)
        expect(minor.tokens.first.hex.id).to eq('J15')
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

      it 'allows the first bid on a later company at face value, then requires 5 more' do
        step = game.round.active_step
        kobe_tram = step.companies[1]

        expect(step.min_bid(kobe_tram)).to eq(40)

        step.process_bid(Action::Bid.new(game.current_entity, company: kobe_tram, price: 40))

        expect(step.min_bid(kobe_tram)).to eq(45)
        expect(step.committed_cash(game.players.first)).to eq(40)
        expect(kobe_tram.owner).to be_nil
      end
    end
  end
end
