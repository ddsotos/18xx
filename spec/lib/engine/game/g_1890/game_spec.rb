# frozen_string_literal: true

require 'spec_helper'

module Engine
  describe Game::G1890::Game do
    let(:players) { %w[A B C] }
    subject(:game) { described_class.new(players) }

    def buy_all_initial_companies(game)
      while game.round.is_a?(Round::Auction)
        auction = game.round.steps.find { |step| step.is_a?(Game::G1890::Step::WaterfallAuction) }
        company = auction.companies.first
        game.process_action(Action::Bid.new(game.current_entity, company: company, price: company.min_bid))
        game.maybe_raise!

        while game.round.is_a?(Round::Auction) && (pending_company = game.round.companies_pending_par.first)
          president_share = game.abilities(pending_company, :shares).shares.find(&:president)
          game.process_action(
            Action::Par.new(
              pending_company.owner,
              corporation: president_share.corporation,
              share_price: game.stock_market.par_prices.first,
            ),
          )
          game.maybe_raise!
        end
      end
    end

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

      it 'models both halves of phases 1 and 2 and phases 3 through 6' do
        expect(described_class::PHASES.map { |phase| [phase[:name], phase[:on]] }).to eq(
          [
            ['1', nil],
            ['1.2', '2-2'],
            ['2', '3'],
            ['2.2', '3-3'],
            ['3', '4'],
            ['4', '5'],
            ['5', '6'],
            ['6', 'D'],
          ],
        )
        expect(described_class::PHASES.map { |phase| phase[:operating_rounds] }).to eq([1, 1, 2, 2, 2, 3, 3, 3])
        expect(described_class::TRAINS.find { |train| train[:name] == 'D' }[:available_on]).to eq('5')
      end

      it 'advances through the first lower half and second phase when trains are bought' do
        corporation = game.corporations.first
        buy_for_phase = lambda do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(corporation, train, train.owner)
        end

        expect(game.phase.name).to eq('1')
        buy_for_phase.call('2')
        expect(game.phase.name).to eq('1')
        buy_for_phase.call('2-2')
        expect(game.phase.name).to eq('1.2')
        buy_for_phase.call('3')
        expect(game.phase.name).to eq('2')
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

      it 'resolves multiple bids after the earlier company is bought' do
        step = game.round.active_step
        arima, kobe_tram = step.companies.first(2)
        player_a, player_b, player_c = game.players

        step.process_bid(Action::Bid.new(player_a, company: kobe_tram, price: 40))
        step.process_bid(Action::Bid.new(player_b, company: kobe_tram, price: 45))
        step.process_bid(Action::Bid.new(player_c, company: arima, price: 20))

        expect(step.active_entities).to eq([player_a])
        expect(step.min_bid(kobe_tram)).to eq(50)

        step.process_pass(Action::Pass.new(player_a))

        expect(kobe_tram.owner).to eq(player_b)
        expect(player_b.cash).to eq(795)
        expect(step.companies).not_to include(kobe_tram)
      end

      it 'gives Arima Railway away when four rounds of passes reduce it to zero' do
        step = game.round.active_step
        arima = step.companies.first

        4.times do
          game.players.size.times do
            step.process_pass(Action::Pass.new(game.current_entity))
          end
        end

        expect(arima.owner).to be_player
        expect(arima.owner.companies).to include(arima)
        expect(step.companies).not_to include(arima)
        expect(arima.min_bid).to eq(0)
      end

      it 'moves to a normal stock round after all eleven companies are bought' do
        buy_all_initial_companies(game)

        expect(game.round).to be_a(Round::Stock)
        expect(game.companies.count(&:owned_by_player?)).to eq(11)
      end
    end

    describe '5 train event' do
      it 'removes private blocking abilities in phase 4 except Osaka City Tram' do
        ordinary_blockers = %w[有電 神電 堺電 京津].map { |id| game.company_by_id(id) }
        osaka_tram = game.company_by_id('市電')

        expect(ordinary_blockers).to all(satisfy { |company| game.abilities(company, :blocks_hexes) })
        expect(game.abilities(osaka_tram, :blocks_hexes)).not_to be_nil

        game.phase.next! until game.phase.name == '4'

        expect(ordinary_blockers).to all(satisfy { |company| game.abilities(company, :blocks_hexes).nil? })
        expect(game.abilities(osaka_tram, :blocks_hexes)).not_to be_nil
      end

      it 'reduces Kobe City Tram and Hankai revenue to 5 in phase 4' do
        companies = %w[神電 堺電].map { |id| game.company_by_id(id) }
        companies.each do |company|
          company.owner = game.players.first
          game.players.first.companies << company
        end

        game.phase.next! until game.phase.name == '4'

        expect(companies.map(&:revenue)).to eq([5, 5])
      end

      it 'prevents corporations from buying Kobe City Tram from phase 4' do
        company = game.company_by_id('神電')
        company.owner = game.players.first
        game.players.first.companies << company
        corporation = game.corporations.first

        game.phase.next! until game.phase.name == '3'
        expect(game.purchasable_companies(corporation)).to include(company)

        game.phase.next!
        expect(game.phase.name).to eq('4')
        expect(game.purchasable_companies(corporation)).not_to include(company)
      end

      it 'closes ordinary privates but keeps Hankai, Osaka City Tram, minors, and latecomers open' do
        game.event_close_companies!

        expect(game.company_by_id('有電')).to be_closed
        expect(game.company_by_id('神電')).to be_closed
        expect(game.company_by_id('堺電')).not_to be_closed
        expect(game.company_by_id('市電')).not_to be_closed
        expect(game.company_by_id('河南')).not_to be_closed
      end
    end

    describe 'Osaka City Tram' do
      it 'closes when Osaka Metro buys its first train' do
        company = game.company_by_id('市電')
        company.owner = game.players.first
        game.players.first.companies << company
        metro = game.corporation_by_id('メトロ')
        train = game.trains.find { |candidate| candidate.name == '2' }

        expect(company).not_to be_closed

        game.buy_train(metro, train, :free)

        expect(company).to be_closed
      end
    end

    describe 'Semboku Rapid Railway' do
      it 'pays 40 to each corporation tokened in Sakai without crashing' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '泉北' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        corporation = game.corporations.first
        city = game.hex_by_id('J11').tile.cities.first
        city.place_token(corporation, corporation.next_token, check_tokenable: false)
        cash_before = corporation.cash

        game.payout_companies

        expect(corporation.cash).to eq(cash_before + 40)
      end
    end

    describe 'Kintetsu conversion' do
      it 'forces Daiki and Hantetsu to merge when the 3-3 train is bought' do
        buy_all_initial_companies(game)
        daiki = game.minor_by_id('大軌')
        hantetsu = game.minor_by_id('阪鉄')
        kintetsu = game.corporation_by_id('近鉄')

        %w[2-2 3 3-3].each do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(game.corporations.first, train, train.owner)
        end

        expect(game.phase.name).to eq('2.2')
        expect(daiki).to be_closed
        expect(hantetsu).to be_closed
        expect(kintetsu.floatable).to be(true)
        expect(kintetsu.cash).to eq(kintetsu.par_price.price * 4 + 300)
      end

      it 'splits Kanan cash between Kintetsu and its president on the 4 train' do
        buy_all_initial_companies(game)
        %w[2-2 3 3-3].each do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(game.corporations.first, train, train.owner)
        end

        kanan = game.minor_by_id('河南')
        kintetsu = game.corporation_by_id('近鉄')
        president = kanan.owner
        game.bank.spend(1, kanan)
        kintetsu_cash = kintetsu.cash
        president_cash = president.cash

        train = game.trains.find { |candidate| candidate.name == '4' }
        game.phase.buying_train!(game.corporations.first, train, train.owner)

        expect(kanan).to be_closed
        expect(kintetsu.cash).to eq(kintetsu_cash + 51)
        expect(president.cash).to eq(president_cash + 50)
      end
    end

    describe 'train rusting' do
      {
        '4' => %w[2],
        '5' => %w[2-2],
        '6' => %w[3 3-3],
        'D' => %w[4],
      }.each do |trigger_name, rusting_names|
        it "rusts #{rusting_names.join(' and ')} when #{trigger_name} is bought" do
          corporation = game.corporations.first
          owned_trains = rusting_names.map do |name|
            train = game.trains.find { |candidate| candidate.name == name }
            game.buy_train(corporation, train, :free)
            train
          end
          trigger = game.trains.find { |candidate| candidate.name == trigger_name }

          game.rust_trains!(trigger, corporation)

          expect(owned_trains.map(&:rusted)).to all(be(true))
        end
      end
    end

    describe 'JR dividends' do
      it 'pays half rounded down to 20 yen units and keeps the remainder' do
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        jr = game.corporation_by_id('JR')
        round.instance_variable_set(:@entities, [jr])
        round.instance_variable_set(:@entity_index, 0)

        expect(step.dividend_types).to eq([:half])
        expect(step.half(jr, 100)).to eq(corporation: 50, per_share: 5.0)
        expect(step.half(jr, 110)).to eq(corporation: 60, per_share: 5.0)
      end
    end
  end
end
