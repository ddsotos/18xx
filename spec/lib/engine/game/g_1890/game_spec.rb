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

    def fully_token_city(city, corporations)
      city.slots.times do |index|
        corporation = corporations[index]
        token = corporation.next_token
        token.place(city)
        city.tokens[index] = token
      end
    end

    describe 'scenario C setup' do
      it 'is listed as a beta game for local playtesting' do
        expect(described_class::DEV_STAGE).to eq(:beta)
      end

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

      it 'uses the prescribed train prices' do
        prices = described_class::TRAINS.to_h { |train| [train[:name], train[:price]] }

        expect(prices).to eq(
          '2' => 80,
          '2-2' => 120,
          '3' => 180,
          '3-3' => 230,
          '4' => 300,
          '5' => 450,
          '6' => 630,
          'D' => 1100,
        )
      end

      it 'defines the train rusting and event triggers' do
        trains = described_class::TRAINS.to_h { |train| [train[:name], train] }

        expect(trains['2'][:rusts_on]).to eq('4')
        expect(trains['2-2'][:rusts_on]).to eq('5')
        expect(trains['3'][:rusts_on]).to eq('6')
        expect(trains['3-3'][:rusts_on]).to eq('6')
        expect(trains['4'][:rusts_on]).to eq('D')
        expect(trains['3-3'][:events].map { |event| event['type'] }).to eq(['conversion_to_Kintetsu'])
        expect(trains['4'][:events].map { |event| event['type'] }).to eq(['kanan_merge_to_Kintetsu'])
        expect(trains['5'][:events].map { |event| event['type'] }).to eq(
          %w[close_companies remove_extra_tile_lay_from_JR],
        )
        expect(trains['6'][:events].map { |event| event['type'] }).to eq(
          %w[Osaka_Expo nara_merge_to_Kintetsu],
        )
      end

      it 'defines display text for all 1890-specific train events' do
        expect(described_class::EVENTS_TEXT.keys).to include(
          'conversion_to_Kintetsu',
          'remove_extra_tile_lay_from_JR',
          'kanan_merge_to_Kintetsu',
          'Osaka_Expo',
          'nara_merge_to_Kintetsu',
        )
      end

      it 'keeps D trains unavailable until the 5 phase and discounts them for 4, 5, or 6 trains' do
        d_train = described_class::TRAINS.find { |train| train[:name] == 'D' }

        expect(d_train[:available_on]).to eq('5')
        expect(d_train[:discount]).to eq('4' => 300, '5' => 300, '6' => 300)
      end

      it 'defines 2-2 and 3-3 trains as town-and-stop split-distance trains' do
        trains = described_class::TRAINS.to_h { |train| [train[:name], train] }

        expect(trains['2-2'][:distance]).to eq(
          [
            { 'nodes' => ['town'], 'pay' => 2, 'visit' => 2 },
            { 'nodes' => %w[city offboard town], 'pay' => 2, 'visit' => 2 },
          ],
        )
        expect(trains['3-3'][:distance]).to eq(
          [
            { 'nodes' => ['town'], 'pay' => 3, 'visit' => 3 },
            { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 },
          ],
        )
      end

      it 'creates an operating minor for each minor certificate' do
        expect(game.minors.map(&:id)).to eq(
          %w[河南 大軌 阪鉄 奈良 神戸],
        )
      end

      it 'uses the prescribed certificate limits' do
        expect(described_class::CERT_LIMIT).to eq(
          2 => 26,
          3 => 18,
          4 => 15,
          5 => 13,
          6 => 11,
          7 => 10,
        )
      end

      it 'uses full capitalization and the 1890 stock-market sale constraints' do
        expect(described_class::BANK_CASH).to eq(12_000)
        expect(described_class::CAPITALIZATION).to eq(:full)
        expect(described_class::MARKET_SHARE_LIMIT).to eq(60)
        expect(described_class::MUST_SELL_IN_BLOCKS).to be(true)
      end

      it 'uses operating-round home token placement and restrictive emergency train buying' do
        expect(described_class::HOME_TOKEN_TIMING).to eq(:operating_round)
        expect(described_class::EBUY_PRES_SWAP).to be(false)
        expect(described_class::EBUY_FROM_OTHERS).to eq(:never)
      end

      it 'uses the prescribed par prices for normal public corporations' do
        expect(game.stock_market.par_prices.map(&:price)).to eq([100, 90, 80, 75, 70, 65])
      end

      it 'uses the prescribed latecomer company face values' do
        values = game
                 .instance_variable_get(:@latecomer_companies)
                 .to_h { |company| [company.id, company.value] }

        expect(values).to eq('京福' => 200, '神高' => 240, '北急' => 280, '泉北' => 320)
      end

      it 'keeps latecomer companies out of the initial auction packet' do
        latecomers = game.instance_variable_get(:@latecomer_companies)

        expect(game.companies & latecomers).to be_empty
        expect(latecomers.size).to eq(4)
        expect(latecomers.map(&:type)).to all(eq(:latecomer))
      end

      it 'keeps all latecomer companies bank-owned and closed to corporate purchase at setup' do
        latecomers = game.instance_variable_get(:@latecomer_companies)

        expect(latecomers.map(&:owner)).to all(eq(game.bank))
        expect(latecomers).to all(satisfy { |company| company.all_abilities.any? { |ability| ability.type == :no_buy } })
        expect(latecomers).to all(
          satisfy { |company| company.all_abilities.any? { |ability| ability.type == :close && ability.on_phase == 'never' } },
        )
      end

      it 'floats Keihan and Hanshin at 40 percent because of their attached shares' do
        expect(game.corporation_by_id('京阪').float_percent).to eq(40)
        expect(game.corporation_by_id('阪神').float_percent).to eq(40)
      end

      it 'creates the prescribed public corporation mix' do
        expect(game.corporations.size).to eq(8)
        expect(game.corporations.count { |corporation| corporation.type == :major }).to eq(7)
        expect(game.corporations.count { |corporation| corporation.type == :national }).to eq(1)
        expect(game.corporation_by_id('JR').type).to eq(:national)
      end

      it 'uses the prescribed token costs for public corporations' do
        expect(game.corporations.map { |corporation| corporation.tokens.map(&:price) }).to eq(
          [
            [0, 40, 100],
            [0, 40, 100],
            [0, 40],
            [0, 40, 100],
            [0, 40, 100, 100],
            [0, 40, 100, 100, 100, 100],
            [0, 0, 0, 0, 40, 100],
            [0],
          ],
        )
      end

      it 'keeps Kintetsu unavailable for ordinary par before conversion' do
        kintetsu = game.corporations[5]

        expect(kintetsu.float_percent).to eq(20)
        expect(kintetsu.floatable).to be(false)
        expect(kintetsu.coordinates).to be_nil
      end

      it 'defines JR as the only national corporation and gives it the national train limit' do
        jr = game.corporation_by_id('JR')

        expect(game.train_limit(jr)).to eq(6)
        expect((game.corporations - [jr]).map(&:type)).not_to include(:national)
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

      it 'uses the prescribed phase tile colors and company-buying status' do
        phases = described_class::PHASES.to_h { |phase| [phase[:name], phase] }

        expect(phases['1'][:tiles]).to eq([:yellow])
        expect(phases['1.2'][:tiles]).to eq([:yellow])
        expect(phases['2'][:tiles]).to eq(%i[yellow green])
        expect(phases['2.2'][:tiles]).to eq(%i[yellow green])
        expect(phases['3'][:tiles]).to eq(%i[yellow green])
        expect(phases['4'][:tiles]).to eq(%i[yellow green brown])
        expect(phases['5'][:tiles]).to eq(%i[yellow green brown])
        expect(phases['6'][:tiles]).to eq(%i[yellow green brown])
        expect(phases.values_at('1', '1.2').map { |phase| phase[:status] }).to eq([nil, nil])
        expect(phases.values_at('2', '2.2', '3', '4', '5', '6').map { |phase| phase[:status] }).to all(
          eq(['can_buy_companies']),
        )
      end

      it 'gives JR two tile lays before the 5 train event' do
        jr = game.corporation_by_id('JR')

        expect(game.tile_lays(jr)).to eq(
          [{ lay: true, upgrade: true }, { lay: true, upgrade: true, cannot_reuse_same_hex: true }],
        )
      end

      it 'uses the prescribed Osaka Metro special tile-lay hexes' do
        expect(described_class::OSAKA_METRO_SPECIAL_TILE_HEXES).to eq(%w[G12 H11 H13])
      end

      it 'advances through all train-triggered phases when trains are bought' do
        buy_all_initial_companies(game)
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
        buy_for_phase.call('3-3')
        expect(game.phase.name).to eq('2.2')
        buy_for_phase.call('4')
        expect(game.phase.name).to eq('3')
        buy_for_phase.call('5')
        expect(game.phase.name).to eq('4')
        buy_for_phase.call('6')
        expect(game.phase.name).to eq('5')
        buy_for_phase.call('D')
        expect(game.phase.name).to eq('6')
      end

      it 'uses left offboard revenue in phases 1 and 2, middle in phases 3 through 5, and right in phase 6' do
        offboard = game.hex_by_id('F1').tile.offboards.first
        train = game.trains.find { |candidate| candidate.name == '4' }

        expect(offboard.route_base_revenue(game.phase, train)).to eq(40)

        game.phase.next! until game.phase.name == '2.2'
        expect(game.phase.name).to eq('2.2')
        expect(offboard.route_base_revenue(game.phase, train)).to eq(40)

        game.phase.next!
        expect(game.phase.name).to eq('3')
        expect(offboard.route_base_revenue(game.phase, train)).to eq(50)

        game.phase.next! until game.phase.name == '6'
        expect(game.phase.name).to eq('6')
        expect(offboard.route_base_revenue(game.phase, train)).to eq(70)
      end

      it 'keeps the 1890-specific city tile inventory' do
        tiles = described_class::TILES

        expect(tiles['GOE']).to include('count' => 1, 'color' => 'green')
        expect(tiles['BOE']).to include('count' => 1, 'color' => 'brown')
        expect(tiles['GON']).to include('count' => 1, 'color' => 'green')
        expect(tiles['BON']).to include('count' => 1, 'color' => 'brown')
        expect(tiles['GKO']).to include('count' => 1, 'color' => 'green')
        expect(tiles['BKO']).to include('count' => 1, 'color' => 'brown')
        expect(tiles['GKY']).to include('count' => 1, 'color' => 'green')
        expect(tiles['BKY']).to include('count' => 1, 'color' => 'brown')
        expect(tiles['BNI']).to include('count' => 1, 'color' => 'brown')
        expect(tiles['BOS']).to include('count' => 1, 'color' => 'brown')
      end

      it 'keeps the prescribed standard yellow tile counts used by scenario C' do
        tiles = described_class::TILES

        expect(tiles.values_at('3', '4', '6', '7', '8', '9')).to eq([2, 3, 2, 4, 8, 7])
        expect(tiles.values_at('57', '58', '63', '69')).to eq([4, 3, 3, 1])
      end

      it 'keeps the prescribed green upgrade tile counts used by scenario C' do
        tiles = described_class::TILES

        expect(tiles.values_at('12', '14', '15', '16', '18', '19', '20')).to eq([2, 2, 2, 2, 1, 2, 2])
        expect(tiles.values_at('23', '24', '25', '26', '27', '28', '29')).to eq([3, 3, 3, 2, 2, 2, 2])
        expect(tiles.values_at('202', '205', '206', '208', '210', '211', '217')).to eq([1, 1, 1, 1, 1, 1, 1])
      end

      it 'starts the three Osaka city hexes with their prescribed yellow labels and revenues' do
        expect(game.hex_by_id('G12').tile.code).to include('revenue:40,slots:2', 'label=ON')
        expect(game.hex_by_id('H11').tile.code).to include('revenue:30', 'label=OW')
        expect(game.hex_by_id('H13').tile.code).to include('revenue:40;city=revenue:40', 'label=OE')
      end

      it 'starts Nara H19 as two 20-revenue cities with an 80 upgrade cost' do
        h19 = game.hex_by_id('H19')

        expect(h19.tile.color).to eq(:yellow)
        expect(h19.tile.code).to include('city=revenue:20;city=revenue:20;upgrade=cost:80')
      end

      it 'keeps the printed Kobe, Kyoto, Sakai, and Nara tiles on their expected hexes' do
        expect(game.hex_by_id('F5').tile.code).to include('label=KO')
        expect(game.hex_by_id('B17').tile.code).to include('label=KY')
        expect(game.hex_by_id('J11').tile.code).to include('label=XX')
        expect(game.hex_by_id('H19').tile.cities.size).to eq(2)
      end

      it 'keeps the printed impassable borders on selected mountain and water hexes' do
        expect(game.hex_by_id('C18').tile.code).to include('border=edge:1,type:impassable')
        expect(game.hex_by_id('D17').tile.code).to include(
          'border=edge:2,type:impassable',
          'border=edge:1,type:impassable',
          'border=edge:4,type:impassable',
        )
        expect(game.hex_by_id('F15').tile.code).to include(
          'border=edge:2,type:impassable',
          'border=edge:1,type:impassable',
        )
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
        expect(game.hex_by_id('B17').tile.cities.map { |city| city.tokened_by?(jr) }).to eq([true, false, false])
        expect(game.hex_by_id('H19').tile.cities.map { |city| city.tokened_by?(jr) }).to eq([false, true])
        expect(jr.all_abilities.select { |ability| ability.type == :reservation }).to be_empty
      end

      it 'places Kobe Electric Railway at D5' do
        kobe = game.minor_by_id('神戸')
        kobe.owner = game.players.first
        kobe.float!

        game.place_home_token(kobe)

        expect(kobe.placed_tokens.map { |token| token.hex.id }).to eq(['D5'])
      end

      it 'keeps Hantetsu tokenless until it is absorbed into Kintetsu' do
        hantetsu = game.minors[2]

        expect(hantetsu.tokens).to be_empty
        expect(hantetsu.coordinates).to be_nil
      end

      it 'defines Nara reservations on Kyoto city 1 and Nara city 0' do
        nara = game.minors[3]

        expect(nara.all_abilities.select { |ability| ability.type == :reservation }.map do |ability|
          [ability.hex, ability.city]
        end).to contain_exactly(['B17', 1], ['H19', 0])
      end

      it 'places Nara Electric Railway in the prescribed Kyoto and Nara cities' do
        nara = game.minor_by_id('奈良')
        nara.owner = game.players.first
        nara.float!

        game.place_home_token(nara)

        expect(nara.placed_tokens.map { |token| token.hex.id }).to contain_exactly('B17', 'H19')
        expect(game.hex_by_id('B17').tile.cities.map { |city| city.tokened_by?(nara) }).to eq([false, true, false])
        expect(game.hex_by_id('H19').tile.cities.map { |city| city.tokened_by?(nara) }).to eq([true, false])
      end

      it 'allows Nara to upgrade H19 to tile 205' do
        nara = game.minor_by_id('奈良')
        nara.owner = game.players.first
        nara.float!
        game.place_home_token(nara)
        game.bank.spend(80, nara)
        game.phase.next! until game.phase.name == '2'

        h19 = game.hex_by_id('H19')
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [nara])
        round.instance_variable_set(:@entity_index, 0)
        track_step = round.steps.find { |step| step.is_a?(Game::G1890::Step::Track) }
        upgrade = game.tiles.find { |tile| tile.name == '205' }
        cash_before = nara.cash

        expect(game.upgrades_to?(h19.tile, upgrade)).to be(true)
        expect(track_step.upgradeable_tiles(nara, h19).map(&:name)).to include('205')

        track_step.process_lay_tile(Action::LayTile.new(nara, hex: h19, tile: upgrade, rotation: 0))

        expect(h19.tile.name).to eq('205')
        expect(nara.cash).to eq(cash_before - 80)
      end

      it 'restricts special brown tiles to their matching city hexes' do
        corporation = game.corporations.first
        round = game.operating_round(1)
        track_step = round.steps.find { |step| step.is_a?(Game::G1890::Step::Track) }
        nishinomiya = game.hex_by_id('F9')
        osaka_west = game.hex_by_id('H11')
        osaka_east = game.hex_by_id('H13')
        green_city_tiles = game.tiles.select { |tile| tile.color == :green && tile.cities.any? }
        nishinomiya.lay(green_city_tiles[0])
        osaka_west.lay(green_city_tiles[1])
        osaka_east.lay(green_city_tiles[2])

        expect(track_step.upgradeable_tiles(corporation, nishinomiya).map(&:name)).to contain_exactly('BNI')
        expect(track_step.upgradeable_tiles(corporation, osaka_west).map(&:name)).to contain_exactly('BOS')
        expect(track_step.upgradeable_tiles(corporation, osaka_east).map(&:name)).not_to include('BNI', 'BOS')
      end
    end

    describe 'initial company packet definitions' do
      it 'uses the prescribed face values and revenues for the eleven initial certificates' do
        companies = game.initial_auction_companies

        expect(companies.map(&:value)).to eq([20, 40, 70, 110, 160, 220, 100, 200, 100, 160, 100])
        expect(companies.map(&:revenue)).to eq([5, 10, 15, 20, 25, 40, 0, 0, 0, 0, 0])
      end

      it 'keeps the first six initial certificates private and the last five minor certificates' do
        companies = game.initial_auction_companies

        expect(companies.first(6).map(&:type)).to all(eq(:private))
        expect(companies.last(5).map(&:type)).to all(eq(:minor))
      end

      it 'defines the initial blocking hexes for the private companies' do
        companies = game.initial_auction_companies
        blocking_hexes = companies.first(6).map do |company|
          company.all_abilities.find { |ability| ability.type == :blocks_hexes }&.hexes&.map(&:id)&.sort
        end

        expect(blocking_hexes).to eq(
          [
            ['D7'],
            ['F5'],
            %w[I12 J11],
            nil,
            %w[B17 B19],
            %w[G12 H11 H13],
          ],
        )
      end

      it 'defines Arima as the only initial private that lays track when sold' do
        companies = game.initial_auction_companies
        track_layers = companies.select { |company| company.all_abilities.any? { |ability| ability.type == :tile_lay } }
        ability = track_layers.first.all_abilities.find { |candidate| candidate.type == :tile_lay }

        expect(track_layers).to eq([companies.first])
        expect(ability.hexes).to eq(['D7'])
        expect(ability.tiles).to eq(%w[3 4 58])
        expect(ability.when).to eq(['sold'])
      end

      it 'defines Hankai and Kobe City Tram revenue reductions for phase 4' do
        companies = game.initial_auction_companies
        revenue_changes = [companies[1], companies[2]].map do |company|
          company.all_abilities.find { |ability| ability.type == :revenue_change }
        end

        expect(revenue_changes.map(&:revenue)).to eq([5, 5])
        expect(revenue_changes.map { |ability| ability.on_phase.to_s }).to eq(%w[4 4])
      end

      it 'defines the attached share certificates in the initial packet' do
        companies = game.initial_auction_companies
        share_companies = companies.select { |company| company.all_abilities.any? { |ability| ability.type == :shares } }

        expect(share_companies).to eq([companies[3], companies[4], companies[5], companies[7]])
        expect(share_companies.map { |company| game.abilities(company, :shares).shares.first.corporation }).to eq(
          [game.corporations[3], game.corporations[1], game.corporations[7], game.corporations[5]],
        )
      end

      it 'defines Kanan, Daiki, and Nara as exchange certificates for reserved Kintetsu shares' do
        companies = game.initial_auction_companies
        exchange_companies = [companies[6], companies[7], companies[9]]
        exchange_abilities = exchange_companies.map do |company|
          company.all_abilities.find { |ability| ability.type == :exchange }
        end

        expect(exchange_abilities.map(&:corporations)).to all(
          eq([game.corporations[5].id]),
        )
        expect(exchange_abilities.map(&:from)).to eq(
          [[:reserved], [:reserved], [:reserved]],
        )
      end

      it 'prevents players from buying initial minor certificates after setup by ordinary company-buying rules' do
        companies = game.initial_auction_companies

        expect(companies.last(5)).to all(
          satisfy { |company| company.all_abilities.any? { |ability| ability.type == :no_buy } },
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

      it 'gives the Osaka Metro president share when Osaka City Tram is bought' do
        company = game.company_by_id('市電')
        player = game.players.first
        company.owner = player
        player.companies << company

        game.after_buy_company(player, company, company.value)

        metro = game.corporation_by_id('メトロ')
        expect(game.round.companies_pending_par).to include(company)

        game.process_action(Action::Par.new(player, corporation: metro, share_price: game.stock_market.par_prices.first))

        expect(player.shares_of(metro).map(&:president)).to include(true)
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

    describe 'latecomer availability' do
      it 'keeps latecomers unavailable throughout game turn 1 and adds them for game turn 2' do
        buy_all_initial_companies(game)
        latecomers = game.instance_variable_get(:@latecomer_companies)

        expect(game.turn).to eq(1)
        expect(game.companies & latecomers).to be_empty

        game.instance_variable_set(:@turn, 2)
        game.new_stock_round

        expect(game.companies).to include(*latecomers)
        expect(game.buyable_bank_owned_companies).to include(*latecomers)
      end

      it 'prevents corporations from buying a latecomer from a player' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '京福' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        expect(game.purchasable_companies(game.corporations.first)).not_to include(company)
      end
    end

    describe 'company purchase in operating rounds' do
      it 'does not allow corporations to buy companies before phase 2' do
        company = game.company_by_id('有電')
        seller = game.players.first
        buyer = game.corporations.first
        company.owner = seller
        seller.companies << company
        game.bank.spend(company.min_price, buyer)
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [buyer])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Engine::Step::BuyCompany) }

        expect(game.phase.name).to eq('1')
        expect(step.actions(buyer)).not_to include('buy_company')
      end

      it 'allows corporations to buy sellable companies from phase 2' do
        company = game.company_by_id('有電')
        seller = game.players.first
        buyer = game.corporations.first
        company.owner = seller
        seller.companies << company
        game.bank.spend(company.min_price, buyer)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [buyer])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Engine::Step::BuyCompany) }

        expect(step.actions(buyer)).to include('buy_company')
        expect(game.purchasable_companies(buyer)).to include(company)
      end

      it 'allows corporations to buy sellable companies in later phases' do
        company = game.company_by_id('有電')
        seller = game.players.first
        buyer = game.corporations.first
        company.owner = seller
        seller.companies << company
        game.bank.spend(company.min_price, buyer)
        game.phase.next! until game.phase.name == '4'
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [buyer])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Engine::Step::BuyCompany) }

        expect(game.phase.status).to include('can_buy_companies')
        expect(step.actions(buyer)).to include('buy_company')
        expect(game.purchasable_companies(buyer)).to include(company)
      end

      it 'enforces the half-to-double price range when buying a company' do
        company = game.company_by_id('有電')
        seller = game.players.first
        buyer = game.corporations.first
        company.owner = seller
        seller.companies << company
        game.bank.spend(company.max_price(buyer), buyer)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [buyer])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Engine::Step::BuyCompany) }

        expect(company.min_price).to eq((company.value / 2.0).ceil)
        expect(company.max_price(buyer)).to eq(company.value * 2)
        expect { step.buy_company(buyer, company, company.min_price - 1, seller) }.to raise_error(GameError)
        expect { step.buy_company(buyer, company, company.max_price(buyer) + 1, seller) }.to raise_error(GameError)

        step.buy_company(buyer, company, company.min_price, seller)

        expect(company.owner).to eq(buyer)
        expect(buyer.companies).to include(company)
      end
    end

    describe 'operating order' do
      it 'does not operate unfloated minors or corporations' do
        minor = game.minors.first
        corporation = game.corporations.first

        expect(minor).not_to be_floated
        expect(corporation).not_to be_floated
        expect(game.operating_order).not_to include(minor)
        expect(game.operating_order).not_to include(corporation)
      end

      it 'operates only floated minors before floated corporations' do
        minor = game.minors.first
        corporation = game.corporations.first
        minor.float!
        game.stock_market.set_par(corporation, game.stock_market.par_prices.find { |price| price.price == 70 })
        corporation.floated = true

        expect(game.operating_order.first).to eq(minor)
        expect(game.operating_order).to include(corporation)
        expect(game.operating_order.index(minor)).to be < game.operating_order.index(corporation)
        expect(game.operating_order).not_to include(*game.minors.drop(1))
      end

      it 'runs floated minors first in company order, then floated corporations by share price' do
        game.minors.each(&:float!)
        nankai = game.corporation_by_id('南海')
        hankyu = game.corporation_by_id('阪急')
        game.stock_market.set_par(nankai, game.stock_market.par_prices.find { |price| price.price == 70 })
        game.stock_market.set_par(hankyu, game.stock_market.par_prices.find { |price| price.price == 100 })
        nankai.floated = true
        hankyu.floated = true

        expect(game.operating_order).to eq([*game.minors, hankyu, nankai])
      end
    end

    describe 'Arima Railway' do
      it 'removes its Arima block when sold to a corporation' do
        seller = game.players.first
        buyer = game.corporations.first
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Engine::Step::BuyCompany) }

        {
          '有電' => ['D7'],
          '神電' => ['F5'],
          '堺電' => %w[I12 J11],
          '京津' => %w[B17 B19],
        }.each do |company_id, hex_ids|
          company = game.company_by_id(company_id)
          company.owner = seller
          seller.companies << company
          game.bank.spend(company.min_price, buyer)

          expect(hex_ids.map { |hex_id| game.hex_by_id(hex_id).tile.blockers }).to all(include(company))

          step.buy_company(buyer, company, company.min_price, seller)

          expect(game.abilities(company, :blocks_hexes)).to be_nil
          expect(hex_ids).to all(satisfy { |hex_id| !game.hex_by_id(hex_id).tile.blockers.include?(company) })
        end
      end

      it 'lays a permitted tile on Arima when sold to a corporation' do
        company = game.company_by_id('有電')
        seller = game.players.first
        buyer = game.corporations.first
        company.owner = buyer
        buyer.companies << company
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::SpecialTrack) }
        round.just_sold_company = company
        round.company_sellers[company] = seller
        hex = game.hex_by_id('D7')
        tile = game.tile_by_id('3-0')

        expect(step.actions(company)).to include('lay_tile')

        step.process_lay_tile(Action::LayTile.new(company, hex: hex, tile: tile, rotation: 0))

        expect(hex.tile.name).to eq('3')
        expect(game.abilities(company, :tile_lay, time: 'sold')).to be_nil
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

      it 'keeps Hankai in the certificate count after phase 4' do
        company = game.company_by_id('堺電')
        player = game.players.first
        company.owner = player
        player.companies << company

        game.phase.next! until game.phase.name == '4'

        expect(company.revenue).to eq(5)
        expect(game.num_certs(player)).to eq(1)
      end

      it 'keeps Kobe City Tram open and in the certificate count after phase 4' do
        company = game.company_by_id('神電')
        player = game.players.first
        company.owner = player
        player.companies << company

        game.phase.next! until game.phase.name == '4'
        game.event_close_companies!

        expect(company).not_to be_closed
        expect(company.revenue).to eq(5)
        expect(game.num_certs(player)).to eq(1)
        expect(game.purchasable_companies(game.corporations.first)).not_to include(company)
      end

      it 'closes ordinary privates but keeps Hankai, Osaka City Tram, minors, and latecomers open' do
        game.event_close_companies!

        expect(game.company_by_id('有電')).to be_closed
        expect(game.company_by_id('神電')).not_to be_closed
        expect(game.company_by_id('堺電')).not_to be_closed
        expect(game.company_by_id('市電')).not_to be_closed
        expect(game.company_by_id('河南')).not_to be_closed
      end
    end

    describe 'Osaka City Tram' do
      it 'cannot be purchased by a corporation' do
        company = game.company_by_id('市電')
        company.owner = game.players.first
        game.players.first.companies << company

        expect(game.purchasable_companies(game.corporations.first)).not_to include(company)
      end

      it 'keeps blocking Osaka city hexes until Osaka Metro starts operating' do
        company = game.company_by_id('市電')
        metro = game.corporation_by_id('メトロ')
        nankai = game.corporation_by_id('南海')
        metro.owner = game.players.first
        nankai.owner = game.players.first
        round = game.operating_round(1)

        expect(game.abilities(company, :blocks_hexes).hexes.map(&:id)).to contain_exactly('G12', 'H11', 'H13')

        round.instance_variable_set(:@entities, [nankai])
        round.instance_variable_set(:@entity_index, 0)
        round.start_operating
        expect(game.abilities(company, :blocks_hexes)).not_to be_nil

        round.instance_variable_set(:@entities, [metro])
        round.instance_variable_set(:@entity_index, 0)
        round.start_operating
        expect(game.abilities(company, :blocks_hexes)).to be_nil
      end

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

      it 'gives Osaka Metro one free special tile lay in Osaka city on its first operation' do
        metro = game.corporation_by_id('メトロ')
        metro.owner = game.players.first
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [metro])
        round.instance_variable_set(:@entity_index, 0)

        round.start_operating
        ability = game.abilities(metro, :tile_lay, time: 'track')

        expect(ability).not_to be_nil
        expect(ability.free).to be(true)
        expect(ability.hexes).to contain_exactly('G12', 'H11', 'H13')
      end

      it 'limits Osaka Metro special tile lay to Osaka city and leaves its normal tile lay after use' do
        2.times { game.phase.next! }
        metro = game.corporation_by_id('メトロ')
        metro.owner = game.players.first
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [metro])
        round.instance_variable_set(:@entity_index, 0)
        round.start_operating
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Track) }
        osaka_north = game.hex_by_id('G12')
        non_osaka = game.hex_by_id('F5')
        tile = game.tiles.find { |candidate| candidate.name == 'GON' }
        cash_before = metro.cash

        expect(step.available_hex(metro, osaka_north)).not_to be_nil
        expect(step.available_hex(metro, non_osaka)).to be_nil

        step.process_lay_tile(Action::LayTile.new(metro, hex: osaka_north, tile: tile, rotation: 2))

        expect(metro.cash).to eq(cash_before)
        expect(game.abilities(metro, :tile_lay, time: 'track')).to be_nil
        expect(round.num_laid_track).to eq(0)
        expect(step.can_lay_tile?(metro)).to be(true)
      end

      it 'removes Osaka Metro special tile lay when its track step is passed' do
        metro = game.corporation_by_id('メトロ')
        metro.owner = game.players.first
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [metro])
        round.instance_variable_set(:@entity_index, 0)
        round.start_operating
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Track) }

        step.process_pass(Action::Pass.new(metro))

        expect(game.abilities(metro, :tile_lay, time: 'track')).to be_nil
      end

      it 'does not grant Osaka Metro special tile lay after its first operation' do
        metro = game.corporation_by_id('メトロ')
        metro.owner = game.players.first
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [metro])
        round.instance_variable_set(:@entity_index, 0)
        round.start_operating
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Track) }

        step.process_pass(Action::Pass.new(metro))
        game.activate_osaka_metro_special_tile_lay!

        expect(game.abilities(metro, :tile_lay, time: 'track')).to be_nil
      end

      it 'ignores token blocking in brown Osaka city hexes' do
        metro = game.corporation_by_id('メトロ')
        osaka_north = game.hex_by_id('G12')
        osaka_north.lay(game.tiles.find { |tile| tile.name == 'BON' })
        city = osaka_north.tile.cities.first

        fully_token_city(city, game.corporations.reject { |corporation| corporation == metro })

        expect(city.blocks?(metro)).to be(false)
      end

      it 'does not ignore token blocking in non-brown Osaka city hexes' do
        metro = game.corporation_by_id('メトロ')
        osaka_north = game.hex_by_id('G12')
        city = osaka_north.tile.cities.first

        fully_token_city(city, game.corporations.reject { |corporation| corporation == metro })

        expect(city.blocks?(metro)).to be(true)
      end

      it 'does not let other corporations ignore token blocking in brown Osaka city hexes' do
        metro = game.corporation_by_id('メトロ')
        nankai = game.corporation_by_id('南海')
        osaka_north = game.hex_by_id('G12')
        osaka_north.lay(game.tiles.find { |tile| tile.name == 'BON' })
        city = osaka_north.tile.cities.first

        fully_token_city(city, game.corporations.reject { |corporation| [metro, nankai].include?(corporation) })

        expect(city.blocks?(nankai)).to be(true)
      end

      it 'does not ignore token blocking outside Osaka city' do
        metro = game.corporation_by_id('メトロ')
        kobe = game.hex_by_id('F5')
        kobe.lay(game.tiles.find { |tile| tile.name == 'BKO' })
        city = kobe.tile.cities.first

        fully_token_city(city, game.corporations.reject { |corporation| corporation == metro })

        expect(city.blocks?(metro)).to be(true)
      end

      it 'keeps token blocking behavior for minors that do not define the Metro exception' do
        minor = game.minor_by_id('奈良')
        osaka_north = game.hex_by_id('G12')
        osaka_north.lay(game.tiles.find { |tile| tile.name == 'BON' })
        city = osaka_north.tile.cities.first

        fully_token_city(city, game.corporations)

        expect(city.blocks?(minor)).to be(true)
      end

      it 'lets Osaka Metro graph walk through tokened brown Osaka city hexes' do
        metro = game.corporation_by_id('メトロ')
        game.hex_by_id('H11').tile.cities.first.place_token(metro, metro.next_token, check_tokenable: false)
        osaka_north = game.hex_by_id('G12')
        osaka_north.lay(game.tiles.find { |tile| tile.name == 'BON' })
        fully_token_city(osaka_north.tile.cities.first, game.corporations.reject { |corporation| corporation == metro })

        graph = game.graph_for_entity(metro)

        expect(graph.connected_nodes(metro).keys.map { |node| node.hex&.id }).to include('G12')
        expect(graph.connected_hexes(metro).keys.compact.map(&:id)).to include('F13', 'G14')
      end

      it 'does not let Osaka Metro graph walk through tokened non-brown Osaka city hexes' do
        metro = game.corporation_by_id('メトロ')
        game.hex_by_id('H11').tile.cities.first.place_token(metro, metro.next_token, check_tokenable: false)
        osaka_north = game.hex_by_id('G12')
        fully_token_city(osaka_north.tile.cities.first, game.corporations.reject { |corporation| corporation == metro })

        graph = game.graph_for_entity(metro)

        expect(graph.connected_nodes(metro).keys.map { |node| node.hex&.id }).not_to include('G12')
        expect(graph.connected_hexes(metro).keys.compact.map(&:id)).not_to include('F13', 'G14')
      end

      it 'allows an Osaka Metro route through a tokened brown Osaka city hex' do
        metro = game.corporation_by_id('メトロ')
        train = game.trains.first
        game.buy_train(metro, train, :free)
        metro_home = game.hex_by_id('H11').tile.cities.first
        metro_home.place_token(metro, metro.next_token, check_tokenable: false)
        osaka_north = game.hex_by_id('G12')
        osaka_north.lay(game.tiles.find { |tile| tile.name == 'BON' })
        fully_token_city(osaka_north.tile.cities.first, game.corporations.reject { |corporation| corporation == metro })
        route = Route.new(game, game.phase, train)

        [metro_home, osaka_north.tile.cities.first].each { |node| route.touch_node(node) }

        expect(route.connection_data).not_to be_empty
        expect(route.revenue).to be_positive
      end

      it 'does not allow an Osaka Metro route through a tokened non-brown Osaka city hex' do
        metro = game.corporation_by_id('メトロ')
        train = game.trains.first
        game.buy_train(metro, train, :free)
        metro_home = game.hex_by_id('H11').tile.cities.first
        metro_home.place_token(metro, metro.next_token, check_tokenable: false)
        osaka_north = game.hex_by_id('G12')
        fully_token_city(osaka_north.tile.cities.first, game.corporations.reject { |corporation| corporation == metro })
        route = Route.new(game, game.phase, train)

        [metro_home, osaka_north.tile.cities.first].each { |node| route.touch_node(node) }

        expect(route.connection_data).to be_empty
        expect { route.revenue }.to raise_error(NoToken)
      end
    end

    describe 'Semboku Rapid Railway' do
      it 'pays 40 to each corporation tokened in Sakai without crashing' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '泉北' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        corporation, other_corporation = game.corporations.first(2)
        city, other_city = game.hex_by_id('J11').tile.cities
        city.place_token(corporation, corporation.next_token, check_tokenable: false)
        other_city.place_token(other_corporation, other_corporation.next_token, check_tokenable: false)
        player_cash_before = player.cash
        cash_before = corporation.cash
        other_cash_before = other_corporation.cash

        game.payout_companies

        expect(player.cash).to eq(player_cash_before + 70)
        expect(corporation.cash).to eq(cash_before + 40)
        expect(other_corporation.cash).to eq(other_cash_before + 40)
      end

      it 'does not pay corporations when nobody has a token in Sakai' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '泉北' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        corporation_cash = game.corporations.to_h { |corporation| [corporation, corporation.cash] }
        player_cash_before = player.cash

        game.payout_companies

        expect(player.cash).to eq(player_cash_before + 70)
        expect(game.corporations).to all(satisfy { |corporation| corporation.cash == corporation_cash[corporation] })
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

    describe 'Kobe Rapid Railway' do
      it 'describes the half-Kobe-revenue ability' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }

        expect(company.value).to eq(240)
        expect(company.revenue).to eq(0)
        expect(company.desc).to include('神戸収益の半額')
      end

      it 'does not operate or have to buy trains' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        expect(game.operating_order).not_to include(company)
        expect(game.must_buy_train?(company)).to be(false)
      end

      it 'lets a corporation buy passage through Kobe for the normal token price' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        other_corporation = game.corporations.find { |candidate| ![corporation.id, 'JR'].include?(candidate.id) }
        kobe_city = game.hex_by_id('F5').tile.cities.first
        jr = game.corporation_by_id('JR')
        kobe_city.place_token(jr, jr.next_token, check_tokenable: false)
        game.bank.spend(100, corporation)
        cash_before = corporation.cash
        bank_cash_before = game.bank.cash
        price = corporation.unplaced_tokens.find { |token| token.price.positive? }.price

        expect(kobe_city.blocks?(corporation)).to be(true)

        game.buy_kobe_rapid_passage!(corporation)

        expect(corporation.cash).to eq(cash_before - price)
        expect(game.bank.cash).to eq(bank_cash_before + price)
        expect(kobe_city.blocks?(corporation)).to be(false)
        expect(kobe_city.blocks?(other_corporation)).to be(true)
      end

      it 'blocks Kobe with its special token after it is bought' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        other_corporation = game.corporations.find { |candidate| ![corporation.id, 'JR'].include?(candidate.id) }
        kobe_city = game.hex_by_id('F5').tile.cities.first

        expect(kobe_city.blocks?(corporation)).to be(false)

        company.owner = player
        player.companies << company
        game.companies << company
        game.activate_kobe_rapid_blocking!

        expect(kobe_city.blocks?(corporation)).to be(true)

        game.bank.spend(100, corporation)
        game.buy_kobe_rapid_passage!(corporation)

        expect(kobe_city.blocks?(corporation)).to be(false)
        expect(kobe_city.blocks?(other_corporation)).to be(true)
      end

      it 'shows the Kobe Rapid special blocking marker on Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        kobe_tile = game.hex_by_id('F5').tile

        expect(kobe_tile.icons.map(&:name)).not_to include('kobe_rapid_block')

        game.activate_kobe_rapid_blocking!
        game.activate_kobe_rapid_blocking!

        expect(kobe_tile.icons.count { |icon| icon.name == 'kobe_rapid_block' }).to eq(1)
      end

      it 'keeps the Kobe Rapid special blocking marker when Kobe is upgraded' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        kobe_hex = game.hex_by_id('F5')

        game.activate_kobe_rapid_blocking!
        kobe_hex.lay(game.tiles.find { |tile| tile.name == 'BKO' })

        expect(kobe_hex.tile.icons.count { |icon| icon.name == 'kobe_rapid_block' }).to eq(1)
      end

      it 'activates Kobe blocking when bought through after_buy_company' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        kobe_city = game.hex_by_id('F5').tile.cities.first
        company.owner = player
        player.companies << company
        game.companies << company

        expect(kobe_city.blocks?(corporation)).to be(false)

        game.after_buy_company(player, company, company.value)

        expect(kobe_city.blocks?(corporation)).to be(true)
      end

      it 'offers Kobe Rapid passage during the token step' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        kobe_city = game.hex_by_id('F5').tile.cities.first
        jr = game.corporation_by_id('JR')
        kobe_city.place_token(jr, jr.next_token, check_tokenable: false)
        game.bank.spend(100, corporation)
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [corporation])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Token) }

        expect(step.actions(corporation)).to include('choose')
        expect(step.choices.keys).to include('buy_kobe_rapid_passage')

        step.process_choose(Action::Choose.new(corporation, choice: 'buy_kobe_rapid_passage'))

        expect(game.kobe_rapid_passage_bought?(corporation)).to be(true)
        expect(kobe_city.blocks?(corporation)).to be(false)
      end

      it 'offers Kobe Rapid passage for its special Kobe block without another token in Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        game.activate_kobe_rapid_blocking!
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        game.bank.spend(100, corporation)
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [corporation])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Token) }

        expect(step.choices.keys).to include('buy_kobe_rapid_passage')
      end

      it 'pays its owner half of Kobe revenue once for a corporation using Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        kobe_hex = instance_double(Hex, location_name: '神戸')
        kobe_stop = double('Kobe stop', hex: kobe_hex)
        allow(kobe_stop).to receive(:route_revenue).and_return(30)
        other_stop = double('Other stop', hex: instance_double(Hex, location_name: '大阪'))
        train = instance_double(Train)
        routes = [
          instance_double(Route, visited_stops: [other_stop, kobe_stop], phase: game.phase, train: train),
          instance_double(Route, visited_stops: [kobe_stop], phase: game.phase, train: train),
        ]
        cash_before = player.cash

        game.pay_kobe_rapid_revenue!(routes)

        expect(player.cash).to eq(cash_before + 15)
      end

      it 'does not pay when no route uses Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        osaka_stop = double('Osaka stop', hex: instance_double(Hex, location_name: '大阪'))
        route = instance_double(Route, visited_stops: [osaka_stop])
        cash_before = player.cash

        game.pay_kobe_rapid_revenue!([route])

        expect(player.cash).to eq(cash_before)
      end

      it 'pays through the dividend step after a route uses Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        corporation = game.corporations.first
        kobe_hex = instance_double(Hex, location_name: '神戸')
        kobe_stop = double('Kobe stop', hex: kobe_hex)
        allow(kobe_stop).to receive(:route_revenue).and_return(30)
        train = instance_double(Train, owner: corporation)
        route = instance_double(
          Route,
          visited_stops: [kobe_stop],
          phase: game.phase,
          train: train,
          connection_hexes: [],
          halts: [],
          node_signatures: [],
        )
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [corporation])
        round.instance_variable_set(:@entity_index, 0)
        round.routes = [route]
        round.extra_revenue = 100
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        allow(game).to receive(:routes_revenue).and_return(0)
        cash_before = player.cash

        step.process_dividend(Action::Dividend.new(corporation, kind: 'withhold'))

        expect(player.cash).to eq(cash_before + 15)
      end

      it 'pays after a corporation buys passage and runs an actual route through Kobe' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '神高' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        corporation = game.corporations.find { |candidate| candidate.id != 'JR' && candidate.unplaced_tokens.any? }
        train = game.trains.find { |candidate| candidate.name == '2' }
        game.buy_train(corporation, train, :free)
        game.bank.spend(100, corporation)
        kobe_hex = game.hex_by_id('F5')
        kobe_hex.lay(game.tiles.find { |tile| tile.name == 'BKO' })
        kobe_city = kobe_hex.tile.cities.first
        kobe_city.place_token(corporation, corporation.next_token, check_tokenable: false)
        game.activate_kobe_rapid_blocking!
        game.buy_kobe_rapid_passage!(corporation)
        f3_tile = game.tiles.find { |tile| tile.name == '6' }
        f3_tile.rotate!(2)
        game.hex_by_id('F3').lay(f3_tile)
        route = Route.new(game, game.phase, train)
        [kobe_city, game.hex_by_id('F3').tile.cities.first].each { |node| route.touch_node(node) }
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [corporation])
        round.instance_variable_set(:@entity_index, 0)
        round.routes = [route]
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        cash_before = player.cash

        expect(route.connection_data).not_to be_empty
        expect(route.visited_stops.map { |stop| stop.hex.location_name }).to include('神戸')

        step.process_dividend(Action::Dividend.new(corporation, kind: 'withhold'))

        expect(player.cash).to eq(cash_before + 30)
      end
    end

    describe 'Keifuku Railway' do
      it 'does not pay Keihan when Keihan has no Kyoto token' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '京福' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company
        keihan = game.corporation_by_id('京阪')
        corporation_cash = keihan.cash
        player_cash = player.cash

        game.payout_companies

        expect(keihan.cash).to eq(corporation_cash)
        expect(player.cash).to eq(player_cash + 40)
      end

      it 'pays 40 to Keihan when it has a token in Kyoto' do
        company = game.instance_variable_get(:@latecomer_companies).find { |candidate| candidate.id == '京福' }
        player = game.players.first
        company.owner = player
        player.companies << company
        game.companies << company

        keihan = game.corporation_by_id('京阪')
        kyoto = game.hex_by_id('B17').tile.cities.last
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
      it 'gives Keihan and Hanshin shares when their privates are bought' do
        player = game.players.first

        { '京津' => '京阪', '阪国' => '阪神' }.each do |company_id, corporation_id|
          company = game.company_by_id(company_id)
          company.owner = player
          player.companies << company

          game.after_buy_company(player, company, company.value)

          expect(player.percent_of(game.corporation_by_id(corporation_id))).to eq(10)
        end
      end

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

    describe 'stock market' do
      it 'marks the yellow market as no-certificate-limit spaces' do
        yellow_prices = game.stock_market.market.flatten.compact.select { |price| price.type == :no_cert_limit }

        expect(yellow_prices.map(&:price)).to include(45, 50)
        expect(yellow_prices).to all(satisfy { |price| price.coordinates[0] >= 4 })
      end

      it 'marks the brown market as unlimited ownership spaces' do
        brown_prices = game.stock_market.market.flatten.compact.select { |price| price.type == :unlimited }

        expect(brown_prices.map(&:price)).to include(30, 35, 40)
        expect(brown_prices).to all(satisfy { |price| price.coordinates[0] >= 6 })
      end

      it 'keeps close spaces only in the bottom-left market area' do
        close_prices = game.stock_market.market.flatten.compact.select { |price| price.type == :close }

        expect(close_prices.map(&:price)).to all(eq(0))
        expect(close_prices.map(&:coordinates)).to contain_exactly([9, 0], [10, 0], [10, 1])
      end

      it 'keeps the normal market share limit at 60 before a corporation enters the brown market' do
        corporation = game.corporations.first
        game.stock_market.set_par(corporation, game.stock_market.par_prices.find { |price| price.price == 70 })

        expect(game.market_share_limit(corporation)).to eq(60)
      end
    end

    describe 'market limits' do
      it 'excludes yellow-market corporations from the certificate count' do
        player = game.players.first
        corporation = game.corporation_by_id('南海')
        yellow_price = game.stock_market.market.flatten.compact.find { |price| price.price == 50 && price.type == :no_cert_limit }
        game.stock_market.set_par(corporation, yellow_price)
        game.share_pool.buy_shares(player, corporation.presidents_share.to_bundle, exchange: :free)

        expect(corporation.counts_for_limit).to be(false)
        expect(game.num_certs(player)).to eq(0)
      end

      it 'allows more than 60 percent ownership for brown-market corporations' do
        corporation = game.corporation_by_id('南海')
        game.stock_market.set_par(corporation, game.stock_market.par_prices.find { |price| price.price == 70 })

        expect(game.market_share_limit(corporation)).to eq(60)

        brown_price = game.stock_market.market.flatten.compact.find { |price| price.price == 40 && price.type == :unlimited }
        corporation.share_price.corporations.delete(corporation)
        corporation.share_price = brown_price

        expect(game.market_share_limit(corporation)).to eq(100)
      end
    end

    describe 'Kintetsu conversion' do
      %w[大軌 阪鉄 河南 奈良].each do |minor_id|
        it "makes an operated train received from #{minor_id} available to Kintetsu" do
          minor = game.minor_by_id(minor_id)
          kintetsu = game.corporation_by_id('近鉄')
          train = game.trains.find { |candidate| candidate.name == '3' && candidate.owner == game.depot }
          game.buy_train(minor, train, :free)
          train.operated = true

          game.transfer_trains(minor, kintetsu)

          expect(train.owner).to eq(kintetsu)
          expect(train.operated).to be(false)
        end
      end

      %w[奈良 河南 神戸 南海].each do |current_id|
        it "starts the Kintetsu special operation before #{current_id} and then resumes the original order" do
          round = game.operating_round(1)
          kintetsu = game.corporation_by_id('近鉄')
          kintetsu.owner = game.players.first
          current = game.minor_by_id(current_id) || game.corporation_by_id(current_id)
          remaining = (game.minors + game.corporations).reject { |entity| [current, kintetsu].include?(entity) }.first(2)
          original_order = [current, *remaining]
          round.instance_variable_set(:@entities, original_order.dup)
          round.instance_variable_set(:@entity_index, 0)

          round.recalculate_order_when_merge_Kintetsu

          expect(round.current_entity).to eq(kintetsu)
          expect(round.current_operator).to eq(kintetsu)
          expect(round.entities).to eq([kintetsu, *original_order])
        end
      end

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

      it 'allows Daiki to exchange from its company certificate through the game action flow' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        daiki = game.minor_by_id('大軌')
        daiki_company = game.company_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        share = kintetsu.treasury_shares.find(&:buyable)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }

        expect(round.actions_for(daiki_company)).to include('buy_shares')
        expect(round.active_step(daiki_company)).to eq(step)
        expect { game.process_action(Action::BuyShares.new(daiki_company, shares: [share])) }.not_to raise_error
        expect(daiki).to be_closed
        expect(kintetsu.floatable).to be(true)
        expect(game.kintetsu_special_operating?).to be(true)
      end

      it 'inserts the Kintetsu special operation when Daiki exchanges through the game action flow' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        daiki_company = game.company_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        current = game.minor_by_id('河南')
        remaining = [game.minor_by_id('神戸'), game.corporation_by_id('南海')]
        original_order = [current, *remaining]
        round.instance_variable_set(:@entities, original_order.dup)
        round.instance_variable_set(:@entity_index, 0)
        round.instance_variable_set(:@current_operator, current)
        share = kintetsu.treasury_shares.find(&:buyable)

        game.process_action(Action::BuyShares.new(daiki_company, shares: [share]))

        expect(round.current_entity).to eq(kintetsu)
        expect(round.current_operator).to eq(kintetsu)
        expect(round.entities).to eq([kintetsu, *original_order])
        expect(game.kintetsu_special_operating?).to be(true)
      end

      it 'can pass through the Kintetsu special operation using game actions' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        daiki_company = game.company_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        current = game.minor_by_id('河南')
        round.instance_variable_set(:@entities, [current, kintetsu])
        round.instance_variable_set(:@entity_index, 0)
        round.instance_variable_set(:@current_operator, current)

        game.process_action(Action::BuyShares.new(daiki_company, shares: [kintetsu.treasury_shares.find(&:buyable)]))

        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::Track)
        expect { game.process_action(Action::Pass.new(kintetsu)) }.not_to raise_error
        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::BuyTrain)
        expect(game.kintetsu_special_operating?).to be(false)
      end

      it 'can run a train received from Daiki in the Kintetsu special operation using game actions' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        daiki = game.minor_by_id('大軌')
        daiki_company = game.company_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        daiki_train = game.trains.find { |train| train.name == '2' && train.owner == game.depot }
        game.buy_train(daiki, daiki_train, :free)
        daiki_train.operated = true
        current = game.minor_by_id('河南')
        remaining = [game.corporation_by_id('南海')]
        round.instance_variable_set(:@entities, [current, *remaining])
        round.instance_variable_set(:@entity_index, 0)
        round.instance_variable_set(:@current_operator, current)

        game.process_action(Action::BuyShares.new(daiki_company, shares: [kintetsu.treasury_shares.find(&:buyable)]))

        expect(round.current_entity).to eq(kintetsu)
        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::Track)
        expect(daiki_train.owner).to eq(kintetsu)
        expect(daiki_train.operated).to be(false)

        h15_tile = game.tiles.find { |tile| tile.name == '6' }
        game.process_action(Action::LayTile.new(kintetsu, tile: h15_tile, hex: game.hex_by_id('H15'), rotation: 1))
        game.process_action(Action::Pass.new(kintetsu))
        kintetsu_token_city = game
                              .hex_by_id('H13')
                              .tile
                              .cities
                              .find { |city| city.tokens.compact.any? { |token| token.corporation == kintetsu } }
        route = Route.new(game, game.phase, daiki_train)
        [kintetsu_token_city, game.hex_by_id('H15').tile.cities.first].each { |node| route.touch_node(node) }
        president_cash = kintetsu.owner.cash
        share_price = kintetsu.share_price

        expect(round.active_step(kintetsu)).to be_a(Step::Route)
        expect(route.connection_data).not_to be_empty
        expect(route.revenue).to eq(60)

        expect { game.process_action(Action::RunRoutes.new(kintetsu, routes: [route])) }.not_to raise_error
        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::Dividend)
        expect { game.process_action(Action::Dividend.new(kintetsu, kind: 'payout')) }.not_to raise_error

        expect(daiki_train.operated).to be(true)
        expect(kintetsu.owner.cash).to eq(president_cash + 12)
        expect(kintetsu.share_price.price).to be > share_price.price
        expect(game.kintetsu_special_operating?).to be(false)
      end

      it 'may run trains received from minors during the Kintetsu special operation' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }
        daiki = game.minor_by_id('大軌')
        kanan = game.minor_by_id('河南')
        kintetsu = game.corporation_by_id('近鉄')
        daiki_train = game.trains.find { |train| train.name == '2' && train.owner == game.depot }
        kanan_train = game.trains.find { |train| train.name == '3' && train.owner == game.depot }
        game.buy_train(daiki, daiki_train, :free)
        game.buy_train(kanan, kanan_train, :free)
        daiki_train.operated = true
        kanan_train.operated = true

        step.process_buy_shares(Action::BuyShares.new(daiki, shares: [kintetsu.treasury_shares.find(&:buyable)]))
        step.process_buy_shares(
          Action::BuyShares.new(kanan, shares: [game.reserved_kintetsu_shares(kintetsu).first]),
        )

        expect(daiki_train.owner).to eq(kintetsu)
        expect(kanan_train.owner).to eq(kintetsu)
        expect(daiki_train.operated).to be(false)
        expect(kanan_train.operated).to be(false)
      end

      it 'allows Kanan to exchange from Show Others during another corporation turn' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        other_corporation = game.corporations.find { |corporation| corporation.id != '近鉄' }
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }
        daiki = game.minor_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        step.process_buy_shares(Action::BuyShares.new(daiki, shares: [kintetsu.treasury_shares.find(&:buyable)]))
        game.finish_kintetsu_special_operating!
        round.instance_variable_set(:@entities, [other_corporation])
        round.instance_variable_set(:@entity_index, 0)
        round.instance_variable_set(:@current_operator, other_corporation)
        kanan = game.minor_by_id('河南')
        kanan_company = game.company_by_id('河南')
        share = game.reserved_kintetsu_shares(kintetsu).first

        expect(round.current_entity).to eq(other_corporation)
        expect(round.actions_for(kanan_company)).to include('buy_shares')
        expect(round.active_step(kanan_company)).to eq(step)
        expect(kintetsu.reserved_shares.first).to eq(share)
        expect(step.can_gain?(kanan_company.owner, share, exchange: true)).to be(true)
        expect { game.process_action(Action::BuyShares.new(kanan_company, shares: [share])) }.not_to raise_error
        expect(kanan).to be_closed
      end

      it 'can run a train received from Kanan after exchange using game actions' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        setup_round = game.operating_round(1)
        game.instance_variable_set(:@round, setup_round)
        step = setup_round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }
        daiki = game.minors[1]
        kintetsu = game.corporations[5]
        step.process_buy_shares(Action::BuyShares.new(daiki, shares: [kintetsu.treasury_shares.find(&:buyable)]))
        game.finish_kintetsu_special_operating!
        kanan = game.minors[0]
        kanan_company = game.initial_auction_companies[6]
        kanan_train = game.trains.find { |train| train.name == '3' && train.owner == game.depot }
        game.buy_train(kanan, kanan_train, :free)
        kanan_train.operated = true
        other_corporation = game.corporations.find { |corporation| corporation != kintetsu }
        setup_round.instance_variable_set(:@entities, [other_corporation])
        setup_round.instance_variable_set(:@entity_index, 0)
        setup_round.instance_variable_set(:@current_operator, other_corporation)

        game.process_action(Action::BuyShares.new(kanan_company, shares: [game.reserved_kintetsu_shares(kintetsu).first]))

        expect(kanan).to be_closed
        expect(kanan_train.owner).to eq(kintetsu)
        expect(kanan_train.operated).to be(false)
        expect(kintetsu.tokens.any? { |token| token.hex&.id == 'J15' }).to be(true)

        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        round.instance_variable_set(:@entities, [kintetsu])
        round.instance_variable_set(:@entity_index, 0)
        round.steps.each(&:unpass!)
        round.steps.each(&:setup)
        round.start_operating
        tile = game.tiles.find { |candidate| candidate.name == '6' }
        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::Track)
        game.process_action(Action::LayTile.new(kintetsu, tile: tile, hex: game.hex_by_id('H15'), rotation: 1))
        game.process_action(Action::Pass.new(kintetsu)) if round.active_step(kintetsu).is_a?(Game::G1890::Step::Track)
        game.process_action(Action::Pass.new(kintetsu)) if round.active_step(kintetsu).is_a?(Game::G1890::Step::Token)
        token_city = game
                     .hex_by_id('H13')
                     .tile
                     .cities
                     .find { |city| city.tokens.compact.any? { |token| token.corporation == kintetsu } }
        route_city = game.hex_by_id('H15').tile.cities.first
        route = Route.new(game, game.phase, kanan_train)
        [token_city, route_city].each { |node| route.touch_node(node) }
        president_cash = kintetsu.owner.cash
        share_price = kintetsu.share_price

        expect(round.active_step(kintetsu)).to be_a(Step::Route)
        expect(route.connection_data).not_to be_empty
        expect(route.revenue).to eq(60)

        expect { game.process_action(Action::RunRoutes.new(kintetsu, routes: [route])) }.not_to raise_error
        expect(round.active_step(kintetsu)).to be_a(Game::G1890::Step::Dividend)
        expect { game.process_action(Action::Dividend.new(kintetsu, kind: 'payout')) }.not_to raise_error

        expect(kanan_train.operated).to be(true)
        expect(kintetsu.owner.cash).to eq(president_cash + 12)
        expect(kintetsu.share_price.price).to be > share_price.price
      end

      it 'allows Nara to exchange from its company certificate through the game action flow' do
        buy_all_initial_companies(game)
        game.phase.next! until game.phase.name == '2'
        round = game.operating_round(1)
        game.instance_variable_set(:@round, round)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Exchange) }
        daiki = game.minor_by_id('大軌')
        kintetsu = game.corporation_by_id('近鉄')
        step.process_buy_shares(Action::BuyShares.new(daiki, shares: [kintetsu.treasury_shares.find(&:buyable)]))
        game.finish_kintetsu_special_operating!
        game.phase.next! until game.phase.name == '4'
        nara = game.minor_by_id('奈良')
        nara_company = game.company_by_id('奈良')
        owner = nara_company.owner
        shares = game.reserved_kintetsu_shares(kintetsu).first(2)

        expect(round.actions_for(nara_company)).to include('buy_shares')
        expect(round.active_step(nara_company)).to eq(step)
        expect { game.process_action(Action::BuyShares.new(nara_company, shares: shares)) }.not_to raise_error
        expect(nara).to be_closed
        expect(owner.percent_of(kintetsu)).to be >= 20
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

      it 'pays route revenue and ends the Kintetsu special operation' do
        kintetsu = game.corporation_by_id('近鉄')
        president = game.players.first
        game.stock_market.set_par(kintetsu, game.stock_market.par_prices.find { |price| price.price == 100 })
        game.share_pool.buy_shares(president, kintetsu.presidents_share.to_bundle, exchange: :free)
        game.instance_variable_set(:@kintetsu_special_operating, true)
        train = instance_double(Train, owner: kintetsu)
        route = instance_double(
          Route,
          revenue: 100,
          visited_stops: [],
          connection_hexes: [],
          halts: [],
          node_signatures: [],
          phase: game.phase,
          train: train,
        )
        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [kintetsu])
        round.instance_variable_set(:@entity_index, 0)
        round.routes = [route]
        dividend = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        president_cash = president.cash
        share_price = kintetsu.share_price

        dividend.process_dividend(Action::Dividend.new(kintetsu, kind: 'payout'))

        expect(president.cash).to eq(president_cash + 20)
        expect(kintetsu.share_price.price).to be > share_price.price
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

      it 'keeps the 40 Kintetsu token available when replacing a merged minor token' do
        daiki = game.minor_by_id('大軌')
        nara = game.minor_by_id('奈良')
        kintetsu = game.corporation_by_id('近鉄')
        game.place_home_token(daiki)
        game.place_home_token(nara)
        game.transfer_minor_token!(daiki.tokens.find { |token| token.hex&.id == 'H13' }, kintetsu)
        forty_token = kintetsu.tokens.find { |token| token.price == 40 }
        transferred_token = nara.tokens.find { |token| token.hex&.id == 'H19' }

        game.transfer_minor_token!(transferred_token, kintetsu)

        h19_city = game.hex_by_id('H19').tile.cities.first
        kintetsu_token = h19_city.tokens.compact.find { |token| token.corporation == kintetsu }
        expect(kintetsu_token.price).to eq(100)
        expect(forty_token.used).to be(false)
        expect(kintetsu.unplaced_tokens).to include(forty_token)
      end

      it 'releases unused Kintetsu reserved shares after the final merger' do
        kintetsu = game.corporation_by_id('近鉄')
        unused_share = kintetsu.treasury_shares.find(&:buyable)
        unused_share.buyable = false

        game.release_reserved_kintetsu_shares!(kintetsu)

        expect(unused_share.buyable).to be(true)
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

      it 'allows a 4, 5, or 6 train to be traded in for a D train at 800' do
        d_train = game.trains.find { |train| train.name == 'D' }

        %w[4 5 6].each do |name|
          exchange_train = game.trains.find { |train| train.name == name }
          expect(d_train.price(exchange_train)).to eq(800)
        end
      end

      it 'reclaims the traded train when a corporation buys a discounted D train' do
        buy_all_initial_companies(game)
        corporation = game.corporations.first
        game.bank.spend(2000, corporation)
        exchange_train = game.trains.find { |train| train.name == '5' }
        game.buy_train(corporation, exchange_train, :free)
        %w[2-2 3 3-3 4 5 6].each do |name|
          train = game.trains.find { |candidate| candidate.name == name }
          game.phase.buying_train!(corporation, train, train.owner)
        end

        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [corporation])
        round.instance_variable_set(:@entity_index, 0)
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::BuyTrain) }
        d_train = game.depot.available(corporation).find { |train| train.name == 'D' }
        cash_before = corporation.cash

        step.process_buy_train(
          Action::BuyTrain.new(corporation, train: d_train, price: 800, exchange: exchange_train),
        )

        expect(corporation.cash).to eq(cash_before - 800)
        expect(d_train.owner).to eq(corporation)
        expect(exchange_train.owner).to eq(game.depot)
      end
    end

    describe 'JR dividends' do
      it 'can lay two tiles before the 5 train event and only one tile after it' do
        jr = game.corporation_by_id('JR')

        expect(game.tile_lays(jr).size).to eq(2)
        expect(game.tile_lays(jr).first[:cannot_reuse_same_hex]).to be_nil
        expect(game.tile_lays(jr).last[:cannot_reuse_same_hex]).to be(true)

        game.event_remove_extra_tile_lay_from_JR!

        expect(game.tile_lays(jr).size).to eq(1)
        expect(game.tile_lays(jr).first[:cannot_reuse_same_hex]).to be_nil
      end

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

      it 'uses route revenue when paying the JR half dividend' do
        jr = game.corporation_by_id('JR')
        president = game.players.first
        par_price = game.stock_market.par_prices.find { |price| price.price == 100 }
        game.stock_market.set_par(jr, par_price)
        game.share_pool.buy_shares(president, jr.presidents_share.to_bundle, exchange: :free)
        train = instance_double(Train, owner: jr)
        route = instance_double(
          Route,
          revenue: 110,
          visited_stops: [],
          connection_hexes: [],
          halts: [],
          node_signatures: [],
          phase: game.phase,
          train: train,
        )

        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [jr])
        round.instance_variable_set(:@entity_index, 0)
        round.routes = [route]
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        corporation_cash = jr.cash
        president_cash = president.cash

        step.process_dividend(Action::Dividend.new(jr, kind: 'half'))

        expect(jr.cash).to eq(corporation_cash + 60)
        expect(president.cash).to eq(president_cash + 10)
      end

      it 'pays the JR half dividend from an actual board route' do
        jr = game.corporation_by_id('JR')
        president = game.players.first
        par_price = game.stock_market.par_prices.find { |price| price.price == 100 }
        game.stock_market.set_par(jr, par_price)
        game.share_pool.buy_shares(president, jr.presidents_share.to_bundle, exchange: :free)
        game.place_home_token(jr)
        train = game.trains.first
        game.buy_train(jr, train, :free)
        osaka_west = game.hex_by_id('H11').tile.cities.first
        osaka_north_hex = game.hex_by_id('G12')
        osaka_north_hex.lay(game.tiles.find { |tile| tile.name == 'BON' })
        osaka_north = osaka_north_hex.tile.cities.first
        osaka_north.place_token(jr, jr.tokens.find { |token| token.hex.nil? }, check_tokenable: false)
        route = Route.new(game, game.phase, train)
        [osaka_west, osaka_north].each { |node| route.touch_node(node) }

        expect(route.connection_data).not_to be_empty
        expect(route.revenue).to eq(110)

        round = game.operating_round(1)
        round.instance_variable_set(:@entities, [jr])
        round.instance_variable_set(:@entity_index, 0)
        round.routes = [route]
        step = round.steps.find { |candidate| candidate.is_a?(Game::G1890::Step::Dividend) }
        corporation_cash = jr.cash
        president_cash = president.cash

        step.process_dividend(Action::Dividend.new(jr, kind: 'half'))

        expect(jr.cash).to eq(corporation_cash + 60)
        expect(president.cash).to eq(president_cash + 10)
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
