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

      it 'uses the prescribed latecomer company face values' do
        values = game
                 .instance_variable_get(:@latecomer_companies)
                 .to_h { |company| [company.id, company.value] }

        expect(values).to eq('京福' => 200, '神高' => 240, '北急' => 280, '泉北' => 320)
      end

      it 'floats Keihan and Hanshin at 40 percent because of their attached shares' do
        expect(game.corporation_by_id('京阪').float_percent).to eq(40)
        expect(game.corporation_by_id('阪神').float_percent).to eq(40)
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

      it 'places all four JR home tokens in their prescribed cities' do
        jr = game.corporation_by_id('JR')

        game.place_home_token(jr)

        expect(jr.placed_tokens.map { |token| token.hex.id }).to contain_exactly('F5', 'G12', 'B17', 'H19')
        expect(jr.all_abilities.select { |ability| ability.type == :reservation }).to be_empty
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

    describe 'Kita-Osaka Kyuko Railway' do
      it 'adds 40 to its first payout after the Osaka Expo event only' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '北急' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        cash_before = player.cash

        game.event_Osaka_Expo!
        game.payout_companies
        expect(player.cash).to eq(cash_before + 100)

        game.payout_companies
        expect(player.cash).to eq(cash_before + 160)
      end
    end

    describe 'Keifuku Railway' do
      it 'pays 40 to Keihan when it has a token in Kyoto' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '京福' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        keihan = game.corporation_by_id('京阪')
        kyoto = game.hex_by_id('B17').tile.cities.first
        kyoto.place_token(keihan, keihan.next_token, check_tokenable: false)
        corporation_cash = keihan.cash
        player_cash = player.cash

        game.payout_companies

        expect(keihan.cash).to eq(corporation_cash + 40)
        expect(player.cash).to eq(player_cash + 40)
      end
    end

    describe 'Hankyu Railway' do
      it 'receives 40 each OR when it has a token in Takarazuka' do
        hankyu = game.corporation_by_id('阪急')
        takarazuka = game.hex_by_id('D9').tile.cities.first
        takarazuka.place_token(hankyu, hankyu.next_token, check_tokenable: false)
        cash_before = hankyu.cash

        game.payout_companies

        expect(hankyu.cash).to eq(cash_before + 40)
      end

      it 'receives 10 whenever it lays a yellow tile' do
        hankyu = game.corporation_by_id('阪急')
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Track) }
        tile = instance_double(Tile, color: :yellow)
        action = instance_double(Action::LayTile, entity: hankyu, tile: tile)
        allow(step).to receive(:lay_tile_action)
        allow(step).to receive(:can_lay_tile?).and_return(false)
        allow(step).to receive(:pass!)
        cash_before = hankyu.cash

        step.process_lay_tile(action)

        expect(hankyu.cash).to eq(cash_before + 10)
      end
    end

    describe 'Hanshin Railway' do
      it 'receives 10 once per OR when a route uses brown Nishinomiya' do
        hanshin = game.corporation_by_id('阪神')
        hex = instance_double(Hex, location_name: '西宮', tile: instance_double(Tile, color: :brown))
        stop = double('stop', hex: hex)
        hanshin_train = instance_double(Train, owner: hanshin)
        routes = Array.new(2) { instance_double(Route, visited_stops: [stop], train: hanshin_train) }

        expect(game.routes_subsidy(routes)).to eq(10)

        hankyu_train = instance_double(Train, owner: game.corporation_by_id('阪急'))
        expect(game.routes_subsidy([instance_double(Route, visited_stops: [stop], train: hankyu_train)])).to eq(0)
      end
    end

    describe 'attached shares' do
      it 'cannot sell the Keihan or Hanshin share before the president share is bought' do
        buy_all_initial_companies(game)
        step = game.round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::BuySellParShares) }

        %w[京阪 阪神].each do |id|
          corporation = game.corporation_by_id(id)
          attached_share = game.players.flat_map { |player| player.shares_of(corporation) }.first
          game.stock_market.set_par(corporation, game.stock_market.par_prices.first)

          expect(step.attached_share_locked?(attached_share.to_bundle)).to be(true)
          expect(step.can_sell?(attached_share.owner, attached_share.to_bundle)).to be(false)

          president = (game.players - [attached_share.owner]).first
          game.share_pool.buy_shares(president, corporation.presidents_share.to_bundle, exchange: :free)
          expect(step.attached_share_locked?(attached_share.to_bundle)).to be(false)
        end
      end
    end

    describe 'Kintetsu conversion' do
      it 'allows optional Daiki conversion from phase 2' do
        buy_all_initial_companies(game)
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }
        daiki = game.minor_by_id('大軌')

        expect(step.can_exchange?(daiki)).to be(false)

        game.phase.next! until game.phase.name == '2'

        expect(step.can_exchange?(daiki)).to be(true)

        kintetsu = game.corporation_by_id('近鉄')
        selected_share = kintetsu.treasury_shares.find(&:buyable)
        step.process_buy_shares(Action::BuyShares.new(daiki, shares: [selected_share]))

        expect(daiki).to be_closed
        kanan = game.minor_by_id('河南')
        nara = game.minor_by_id('奈良')
        expect(step.can_exchange?(kanan)).to be(true)
        expect(step.can_exchange?(nara)).to be(false)

        kanan_share = game.reserved_kintetsu_shares(kintetsu).first
        step.process_buy_shares(Action::BuyShares.new(kanan, shares: [kanan_share]))
        expect(kanan).to be_closed

        game.phase.next! until game.phase.name == '4'

        expect(step.can_exchange?(nara)).to be(true)
        nara_shares = game.reserved_kintetsu_shares(kintetsu).first(2)
        step.process_buy_shares(Action::BuyShares.new(nara, shares: nara_shares))
        expect(nara).to be_closed
      end

      it 'forces Daiki and Hantetsu to merge when the 3-3 train is bought' do
        buy_all_initial_companies(game)
        daiki = game.minor_by_id('大軌')
        hantetsu = game.minor_by_id('阪鉄')
        kintetsu = game.corporation_by_id('近鉄')
        hantetsu_owner = hantetsu.owner
        hantetsu_train = game.trains.find { |candidate| candidate.name == '2' && candidate.owner == game.depot }
        game.buy_train(hantetsu, hantetsu_train, :free)

        %w[2-2 3 3-3].each do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(game.corporations.first, train, train.owner)
        end

        expect(game.phase.name).to eq('2.2')
        expect(daiki).to be_closed
        expect(hantetsu).to be_closed
        expect(kintetsu.floatable).to be(true)
        expect(kintetsu.cash).to eq(kintetsu.par_price.price * 4 + 300)
        expect(hantetsu_owner.shares_of(kintetsu).reject(&:president).map(&:buyable)).to include(false)
        expect(hantetsu_train.owner).to eq(kintetsu)
        expect(kintetsu.trains).to include(hantetsu_train)
        expect(game.kintetsu_special_operating?).to be(true)

        round = game.operating_round(1)
        dividend = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        expect(dividend.share_price_change(kintetsu, 0)).to eq({})
        expect(dividend.share_price_change(kintetsu, 100)).to eq(share_direction: :right, share_times: 1)

        round.instance_variable_set(:@entities, [kintetsu])
        round.instance_variable_set(:@entity_index, 0)
        share_price = kintetsu.share_price
        dividend.process_dividend(Action::Dividend.new(kintetsu, kind: 'withhold'))

        expect(kintetsu.share_price).to eq(share_price)
        expect(game.kintetsu_special_operating?).to be(false)
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
        kanan_train = game.trains.find { |candidate| candidate.name == '3' && candidate.owner == game.depot }
        game.buy_train(kanan, kanan_train, :free)
        game.bank.spend(1, kanan)
        kintetsu_cash = kintetsu.cash
        president_cash = president.cash

        train = game.trains.find { |candidate| candidate.name == '4' }
        game.phase.buying_train!(game.corporations.first, train, train.owner)

        expect(kanan).to be_closed
        expect(kintetsu.cash).to eq(kintetsu_cash + 51)
        expect(president.cash).to eq(president_cash + 50)
        expect(president.shares_of(kintetsu).map(&:buyable)).to include(false)
        expect(kanan_train.owner).to eq(kintetsu)
        expect(kintetsu.trains).to include(kanan_train)
      end

      it 'forces Nara to merge for two reserved shares on the 6 train' do
        buy_all_initial_companies(game)
        nara = game.minor_by_id('奈良')
        kintetsu = game.corporation_by_id('近鉄')
        president = nara.owner

        %w[2-2 3 3-3 4 5].each do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(game.corporations.first, train, train.owner)
        end
        cash_before = kintetsu.cash
        percent_before = president.percent_of(kintetsu)

        train = game.trains.find { |candidate| candidate.name == '6' }
        game.phase.buying_train!(game.corporations.first, train, train.owner)

        expect(game.phase.name).to eq('5')
        expect(nara).to be_closed
        expect(kintetsu.cash).to eq(cash_before + 160)
        expect(president.percent_of(kintetsu)).to eq(percent_before + 20)
        expect(kintetsu.treasury_shares.reject(&:buyable)).to be_empty
        expect(kintetsu.tokens.any? { |token| token.hex&.id == 'H19' }).to be(true)
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

      it 'pays the corporation and president and moves the share price right' do
        jr = game.corporation_by_id('JR')
        president = game.players.first
        par_price = game.stock_market.par_prices.find { |price| price.price == 100 }
        game.stock_market.set_par(jr, par_price)
        game.share_pool.buy_shares(president, jr.presidents_share.to_bundle, exchange: :free)

        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [jr])
        round.instance_variable_set(:@entity_index, 0)
        round.extra_revenue = 110
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        corporation_cash = jr.cash
        president_cash = president.cash
        share_price = jr.share_price

        step.process_dividend(Action::Dividend.new(jr, kind: 'half'))

        expect(jr.cash).to eq(corporation_cash + 60)
        expect(president.cash).to eq(president_cash + 10)
        expect(jr.share_price.price).to be > share_price.price
      end
    end

    describe 'minor dividends' do
      it 'always splits revenue equally between the treasury and president without a price move' do
        minor = game.minors.first
        president = game.players.first
        minor.owner = president
        minor.float!

        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [minor])
        round.instance_variable_set(:@entity_index, 0)
        round.extra_revenue = 100
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        minor_cash = minor.cash
        president_cash = president.cash

        expect(step.actions(minor)).to be_empty
        expect(step.share_price_change(minor, 100)).to be_empty

        step.process_dividend(Action::Dividend.new(minor, kind: 'payout'))

        expect(minor.cash).to eq(minor_cash + 50)
        expect(president.cash).to eq(president_cash + 50)
      end
    end
  end
end
