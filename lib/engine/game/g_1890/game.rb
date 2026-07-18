# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/special_track'
require_relative 'step/token'
require_relative 'step/waterfall_auction'
require_relative '../base'

module Engine
  module Game
    module G1890
      class Game < Game::Base
        include_meta(G1890::Meta)
        include Entities
        include Map

        register_colors(black: '#37383a',
                        orange: '#f48221',
                        brightGreen: '#76a042',
                        red: '#d81e3e',
                        turquoise: '#00a993',
                        blue: '#0189d1',
                        brown: '#7b352a')

        CURRENCY_FORMAT_STR = '¥%s'

        BANK_CASH = 12000

        CERT_LIMIT = { 2 => 26, 3 => 18, 4 => 15, 5 => 13, 6 => 11, 7 => 10 }.freeze

        STARTING_CASH = { 2 => 1260, 3 => 840, 4 => 630, 5 => 504, 6 => 420, 7 => 360 }.freeze

        CAPITALIZATION = :full

        MARKET_SHARE_LIMIT = 60

        MUST_SELL_IN_BLOCKS = true

        MARKET = [
          %w[70 75 80 90 100p 110 125 150 175 200 225 250 275 300 325 350 375 400],
          %w[65 70 75 80 90p 100 110 125 150 175 200 225 250 275 300 325 350 375],
          %w[60 65 70 75 80p 90 100 110 125 150 175 200 225 250 275 300],
          %w[55 60 65 70 75p 80 90 100 110 125 150 175 200 225],
          %w[50y 55 60 65 70p 75 80 90 100 110 125 150],
          %w[45y 50y 55 60 65p 70 75 80 90 100],
          %w[40o 45y 50y 55 60 65 70 75],
          %w[35o 40o 45y 50y 55 60],
          %w[30o 35o 40o 45y 50y],
          %w[0c 30o 35o 40o 45y],
          %w[0c 0c 30o 35o 40o],
        ].freeze

        PHASES = [
          {
            name: '1',
            train_limit: { minor: 2, major: 4, national: 6 },
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '1.2',
            on: '2-2',
            train_limit: { minor: 2, major: 4, national: 6 },
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '2',
            on: '3',
            train_limit: { minor: 2, major: 4, national: 6 },
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '2.2',
            on: '3-3',
            train_limit: { minor: 2, major: 4, national: 6 },
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '3',
            on: '4',
            train_limit: { minor: 1, major: 3, national: 4 },
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '5',
            train_limit: { minor: 1, major: 2, national: 3 },
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '6',
            train_limit: { minor: 1, major: 2, national: 3 },
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['can_buy_companies'],
          },
          {
            name: '6',
            on: 'D',
            train_limit: { minor: 1, major: 2, national: 3 },
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['can_buy_companies'],
          },
        ].freeze

        TRAINS = [
          {
            name: '2',
            distance: 2,
            price: 80,
            rusts_on: '4',
            num: 9,
          },
          {
            name: '2-2',
            distance: [{ 'nodes' => ['town'], 'pay' => 2, 'visit' => 2 },
                       { 'nodes' => %w[city offboard town], 'pay' => 2, 'visit' => 2 }],
            price: 120,
            rusts_on: '5',
            num: 3,
          },
          {
            name: '3',
            distance: 3,
            price: 180,
            rusts_on: '6',
            num: 5,
          },
          {
            name: '3-3',
            distance: [{ 'nodes' => ['town'], 'pay' => 3, 'visit' => 3 },
                       { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 }],
            price: 230,
            rusts_on: '6',
            num: 2,
            events: [{ 'type' => 'conversion_to_Kintetsu' }],
          },
          {
            name: '4',
            distance: 4,
            price: 300,
            rusts_on: 'D',
            num: 4,
            events: [{ 'type' => 'kanan_merge_to_Kintetsu' }],
          },
          {
            name: '5',
            distance: 5,
            price: 450,
            num: 3,
            events: [{ 'type' => 'close_companies' },
                     { 'type' => 'remove_extra_tile_lay_from_JR' },],
          },
          { name: '6', distance: 6, price: 630, num: 2,
            events: [{ 'type' => 'Osaka_Expo' },
                     { 'type' => 'nara_merge_to_Kintetsu' }],
          },
          {
            name: 'D',
            distance: 999,
            price: 1100,
            num: 6,
            available_on: '5',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
          },
].freeze
        @Osaka_Expo_timing = false
        EBUY_PRES_SWAP = false # allow presidential swaps of other corps when ebuying
        EBUY_FROM_OTHERS = :never # allow ebuying other corp trains for up to face
        HOME_TOKEN_TIMING = :operating_round
        EXTRA_TILE_LAYS = [{ lay: true, upgrade: true },
                           { lay: true, upgrade: true, cannot_reuse_same_hex: true },].freeze
        OSAKA_METRO_SPECIAL_TILE_HEXES = %w[G12 H11 H13].freeze
        OFFBOARD_REVENUE_PHASES = {
          %w[1 1.2 2 2.2] => :yellow,
          %w[3 4 5] => :brown,
          %w[6] => :diesel,
        }.freeze

        INITIAL_AUCTION_ORDER = %w[有電 神電 堺電 阪国 京津 市電 河南 大軌 阪鉄 奈良 神戸].freeze

        EVENTS_TEXT = Base::EVENTS_TEXT.dup.merge(
          'conversion_to_Kintetsu' => ['近鉄への強制転換', '大阪電気軌道がまだ近鉄に転換していなければ、強制転換（大阪鉄道も合併）'],
          'remove_extra_tile_lay_from_JR' => ['JRの2タイル配置終了', 'JRは、ここまでは2か所でタイル配置できる'],
          'kanan_merge_to_Kintetsu' => ['河南の強制合併', '近鉄開始以降合併可だが、このタイミングで強制合併'],
          'Osaka_Expo' => ['万博(1970)', '北大阪急行が一度だけ40の追加配当を行う'],
          'nara_merge_to_Kintetsu' => ['奈良電鉄の強制合併', '奈良電鉄を近鉄20%株と交換して強制合併する'],
          ).freeze



        def setup_preround
          @companies, @latecomer_companies = @companies.partition do 
            |c| c.type != :latecomer
          end
          @companies.each { |c| @log << "is #{c.type} " }
          @latecomer_companies.each { |c| c.owner = @bank}
        end

        def setup
          super
          configure_offboard_revenue!
          jr = @corporations.find{|c| c.name == 'JR'}
          jr.add_ability(Engine::Ability::Base.new(
            type: 'extra_tile_lay',# entityでこの能力を記述すると、対応する能力クラスがなくて落ちる
          ))
          metro = corporation_by_id('メトロ')
          metro.define_singleton_method(:ignores_token_blocking?) do |city|
            city.hex&.tile&.color == :brown &&
              Engine::Game::G1890::Game::OSAKA_METRO_SPECIAL_TILE_HEXES.include?(city.hex.id)
          end
          @osaka_metro_special_tile_lay_used = false

        end

        def initial_auction_companies
          INITIAL_AUCTION_ORDER.map { |id| @companies.find { |company| company.id == id } }
        end

        def configure_offboard_revenue!
          @hexes.each do |hex|
            hex.tile.offboards.each do |offboard|
              offboard.define_singleton_method(:route_base_revenue) do |phase, _train|
                _, revenue_key = Engine::Game::G1890::Game::OFFBOARD_REVENUE_PHASES.find do |phase_names, _key|
                  phase_names.include?(phase.name)
                end

                revenue[revenue_key] || 0
              end
            end
          end
        end

        def new_auction_round
          Engine::Round::Auction.new(self, [
            Engine::Step::CompanyPendingPar,
            G1890::Step::WaterfallAuction,
          ])
        end

      def stock_round
        Engine::Round::Stock.new(self, [
          Engine::Step::DiscardTrain,
          Engine::Step::Exchange,
          Engine::Step::SpecialTrack,
          G1890::Step::BuySellParShares,
        ])
      end


        def operating_round(round_num)
          G1890::Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            G1890::Step::Exchange,
            G1890::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            G1890::Step::Track,
            G1890::Step::Token,
            Engine::Step::Route,
            G1890::Step::Dividend,
            Engine::Step::DiscardTrain,
            G1890::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        def must_buy_train?(entity)
          return false unless entity&.operator?

          super
        end

        def active_players
          return super if @finished

          company = company_by_id('ER')
          current_entity == company ? [@round.company_sellers[company]] : super
        end

        def bank_first?
          false
        end

        def new_stock_round
          @log << "new stock round. old round is #{@turn} "

          case @turn
          when 1
            @corporations.each{
            |c| if c.name == '近鉄'
                shares =c.ipo_shares
                shares[4].buyable = false
                shares[5].buyable = false
                shares[6].buyable = false
                shares[7].buyable = false

              end
            }
          when 2
            @companies += @latecomer_companies

            update_cache(:companies)
          end

          super
        end

        def unowned_purchasable_companies(_entity)
          @companies.select { |c| !c.owned_by_player? }
        end

        def purchasable_companies(entity = nil)
          companies = super
          return companies unless @phase.available?('4')

          companies.reject { |company| company.id == '神電' }
        end

        def market_share_limit(corporation = nil)
          return 100 if corporation&.share_price&.type == :unlimited

          super
        end

        def num_certs(entity)
          certs = super
          certs -= entity.companies.count { |company| kobe_electric_latecomerized?(company) } if entity.respond_to?(:companies)
          certs
        end

        def home_token_can_be_cheater
          true
        end

        def latecomerize_kobe_electric!
          minor = minor_by_id('神戸')
          company = company_by_id('神戸')
          raise GameError, 'Kobe Electric is not owned' unless minor&.owner && company&.owner
          return if kobe_electric_latecomerized?(company)

          owner = company.owner
          minor.placed_tokens.dup.each(&:remove!)
          transfer_trains(minor, @depot)
          minor.spend(minor.cash, @bank) if minor.cash.positive?
          minor.close!

          company.value = 0
          company.revenue = 0
          company.meta[:latecomerized] = true
          company.desc = "#{company.desc}\n後発会社化済み。額面価格は¥0で、持ち株制限に含めません。"

          @log << "#{owner.name} declares #{company.name} as a latecomer company"
          clear_graph
        end

        def kobe_electric_latecomerized?(company)
          company&.id == '神戸' && company.meta[:latecomerized] == true
        end

        def kintetsu_special_operating?
          @kintetsu_special_operating == true
        end

        def finish_kintetsu_special_operating!
          @kintetsu_special_operating = false
        end

        def release_osaka_city_tram_blocks!
          osaka_tram = company_by_id('市電')
          ability = abilities(osaka_tram, :blocks_hexes)
          osaka_tram.remove_ability(ability) if ability
        end

        def activate_osaka_metro_special_tile_lay!
          return if @osaka_metro_special_tile_lay_used

          metro = corporation_by_id('メトロ')
          return if abilities(metro, :tile_lay, time: 'track')

          metro.add_ability(Engine::Ability::TileLay.new(
            type: 'tile_lay',
            when: 'track',
            tiles: [],
            hexes: OSAKA_METRO_SPECIAL_TILE_HEXES,
            free: true,
            count: 1,
            consume_tile_lay: true,
          ))
        end

        def osaka_metro_special_tile_lay?(entity, hex = nil)
          return false unless entity&.id == 'メトロ'

          ability = abilities(entity, :tile_lay, time: 'track')
          return false unless ability&.free

          hex.nil? || ability.hexes.include?(hex.id)
        end

        def finish_osaka_metro_special_tile_lay!
          metro = corporation_by_id('メトロ')
          ability = abilities(metro, :tile_lay, time: 'track')
          metro.remove_ability(ability) if ability
          @osaka_metro_special_tile_lay_used = true
        end

        def place_home_token(corporation)
          return super unless %w[JR 奈良].include?(corporation.id)
          return if corporation.tokens.first&.used

          reservations = corporation.all_abilities.select { |ability| ability.type == :reservation }
          locations = Array(corporation.coordinates).to_h { |coord| [coord, nil] }
          reservations.each { |reservation| locations[reservation.hex] = reservation.city }

          locations.each do |coord, city_index|
            hex = hex_by_id(coord)
            tile = hex&.tile
            cities = tile.cities
            city = city_index.nil? ? cities.find { |candidate| candidate.reserved_by?(corporation) } : cities[city_index]
            city ||= cities.first
            token = corporation.find_token_by_type

            @log << "#{corporation.name} places a token on #{hex.name}"
            city.place_token(corporation, token)
          end

          reservations.each { |reservation| corporation.remove_ability(reservation) }

          @graph.clear
        end
        
      def event_conversion_to_Kintetsu!
        return unless daiki = @minors.find { |m| m.name == "大軌" }
        kintetsu = @corporations.find{|c| c.name == '近鉄'}
        exchange_minor(daiki,kintetsu.shares[0].to_bundle)
      end

      def event_kanan_merge_to_Kintetsu!
        return unless kanan = @minors.find { |m| m.name == "河南" }
        kintetsu = @corporations.find{|c| c.name == '近鉄'}
        exchange_minor(kanan, reserved_kintetsu_shares(kintetsu).first.to_bundle)
      end

      def event_remove_extra_tile_lay_from_JR!
        jr = @corporations.find{|c| c.name == 'JR'}
        jr.remove_ability(jr.all_abilities.find { |ability| ability.type == :extra_tile_lay})
      end

      def event_Osaka_Expo!
        @Osaka_Expo_timing = true
      end

      def event_nara_merge_to_Kintetsu!
        nara = @minors.find { |minor| minor.name == '奈良' }
        return unless nara&.owner && !nara.closed?

        kintetsu = @corporations.find { |corporation| corporation.name == '近鉄' }
        bundle = Engine::ShareBundle.new(reserved_kintetsu_shares(kintetsu).first(2))
        exchange_minor(nara, bundle)
        release_reserved_kintetsu_shares!(kintetsu)
      end



      def payout_companies(ignore: [])
        companies = companies_to_payout(ignore: ignore)

        companies.sort_by! do |company|
          owner = company.owner
          owner_key = if company.owned_by_player?
                        [0, @players.index(owner) || @players.size, owner.name]
                      else
                        [1, owner.class.name, owner.respond_to?(:id) ? owner.id.to_s : owner.name.to_s]
                      end
          [
            owner_key,
            company.revenue,
            company.name,
          ]
        end

        companies.each do |company|
          
          owner = company.owner
          next if owner == bank
          case company.sym
          when "京福"
            keihan = @corporations.find{|c| c.name == '京阪'}
            if keihan.tokens.find{|t| t.hex&.location_name == '京都'}
              @bank.spend(40, keihan)
              @log << "#{keihan.name} have token in 京都, so collects 40 from 京福"
            end
          when "泉北"
            @corporations.select{|c| c.tokens.find{|t| t.hex&.location_name == '堺'}}.each do |c| 
              bank.spend(40, c)
              @log << "#{c.name} have token in 堺, so collects 40 from 泉北"
            end
          when "北急"
            if @Osaka_Expo_timing
              bank.spend(40, owner)
              @log << "#{owner.name} collects 40 from 北急 as Expo special revenue"
              @Osaka_Expo_timing = false
            end
          end
          revenue = company.revenue
          @bank.spend(revenue, owner)
          @log << "#{owner.name} collects #{format_currency(revenue)} from #{company.name}"
        end

        hankyu = corporation_by_id('阪急')
        return unless hankyu.tokens.any? { |token| token.hex&.location_name == '宝塚' }

        @bank.spend(40, hankyu)
        @log << "#{hankyu.name} collects #{format_currency(40)} for its Takarazuka token"
      end

      def routes_subsidy(routes)
        return super if routes.empty? || routes.first.train.owner&.id != '阪神'

        uses_brown_nishinomiya = routes.any? do |route|
          route.visited_stops.any? do |stop|
            stop.hex.location_name == '西宮' && stop.hex.tile.color == :brown
          end
        end
        uses_brown_nishinomiya ? 10 : 0
      end

      def kobe_rapid_revenue(routes)
        routes.each do |route|
          kobe_stop = route.visited_stops.find { |stop| stop.hex.location_name == '神戸' }
          return kobe_stop.route_revenue(route.phase, route.train) / 2 if kobe_stop
        end

        0
      end

      def pay_kobe_rapid_revenue!(routes)
        company = company_by_id('神高') || @latecomer_companies.find { |candidate| candidate.id == '神高' }
        return unless company&.owned_by_player?

        revenue = kobe_rapid_revenue(routes)
        return unless revenue.positive?

        bank.spend(revenue, company.owner)
        @log << "#{company.owner.name} collects #{format_currency(revenue)} from #{company.name} for Kobe revenue"
      end

      def buy_kobe_rapid_passage!(corporation)
        company = company_by_id('神高') || @latecomer_companies.find { |candidate| candidate.id == '神高' }
        raise GameError, 'Kobe Rapid Railway is not owned by a player' unless company&.owned_by_player?
        return if kobe_rapid_passage_bought?(corporation)

        token = corporation.unplaced_tokens.find { |candidate| candidate.price.positive? }
        raise GameError, "#{corporation.name} has no paid token available" unless token

        passage_price = token.price
        corporation.spend(passage_price, bank)
        (@kobe_rapid_passage_corporations ||= []) << corporation
        token.price = 100 if token.price == 40
        update_kobe_rapid_passage_description!(company)
        previous_ignores_token_blocking = corporation.method(:ignores_token_blocking?)
        corporation.define_singleton_method(:ignores_token_blocking?) do |city|
          previous_ignores_token_blocking.call(city) || city.hex&.id == 'F5'
        end
        clear_graph_for_entity(corporation)
        @log << "#{corporation.name} buys Kobe Rapid passage for #{format_currency(passage_price)}"
      end

      def update_kobe_rapid_passage_description!(company)
        @kobe_rapid_base_description ||= company.desc
        buyers = (@kobe_rapid_passage_corporations || []).map(&:name).join('、')
        company.desc = "#{@kobe_rapid_base_description}\n通過権購入済み: #{buyers}"
      end

      def kobe_rapid_passage_bought?(corporation)
        (@kobe_rapid_passage_corporations || []).include?(corporation)
      end

      def kobe_rapid_available?
        company = company_by_id('神高') || @latecomer_companies.find { |candidate| candidate.id == '神高' }
        company&.owned_by_player?
      end

      def activate_kobe_rapid_blocking!
        return if @kobe_rapid_blocking_active

        kobe_hex = hex_by_id('F5')
        kobe_tile = kobe_hex.tile
        kobe_tile.icons << Part::Icon.new('red_cube', 'kobe_rapid_block') unless
          kobe_tile.icons.any? { |icon| icon.name == 'kobe_rapid_block' }
        kobe_city = kobe_tile.cities.first
        previous_blocks = kobe_city.method(:blocks?)
        game = self
        kobe_city.define_singleton_method(:blocks?) do |corporation|
          previous_blocks.call(corporation) ||
            (corporation &&
             !tokened_by?(corporation) &&
             !game.kobe_rapid_passage_bought?(corporation))
        end
        @kobe_rapid_blocking_active = true
        clear_graph
      end


      def after_buy_company(player, company, _price)
        company.value = 0 if company.id == '市電'
        activate_kobe_rapid_blocking! if company.id == '神高'

        abilities(company, :shares) do |ability|
          ability.shares.each do |share|
            if share.president
              @round.companies_pending_par << company
              @log << "share.president"
            else
              share_pool.buy_shares(player, share, exchange: :free)
            end
          end
        end
        abilities(company, :acquire_company) do |ability|
          acquired_company = company_by_id(ability.company)
          acquired_company.owner = player
          player.companies << acquired_company
          @log << "#{player.name} receives #{acquired_company.name}"
          after_buy_company(player, acquired_company, 0)
        end
        acquire_minor(company)
      end

      def after_sell_company(buyer, company, _price, _seller)
        return unless buyer&.corporation?

        company.all_abilities.dup.each do |ability|
          company.remove_ability(ability) if ability.type == :blocks_hexes
        end
        clear_graph
      end

        def acquire_minor(company)
          return unless (minor = @minors.find { |m| m.name == company.sym })
          minor.owner = company.player
          @bank.spend(company.treasury, minor)
          minor.float!
          place_home_token(minor)
        end
      def city_tokened_by?(city, entity)
        if entity.name == '阪鉄'
          daiki = @minors.find { |m| m.name == '大軌' }
          return city.tokened_by?(daiki)
        end
        # if entity.name == 'メトロ'
        #   return city.tokens.any? { |t| t&.corporation == entity }
        # end
        super
      end

      def upgrade_ignore_num_cities(from)
        from.hex.id == 'H19' && from.color == :yellow
      end

          def exchange_minor(minor, bundle)
            corporation = bundle.corporation
            source = bundle.owner
            # unless can_gain?(minor.owner, bundle, exchange: true)
            #   raise GameError, "#{minor.name} cannot be exchanged for #{corporation.name}"
            # end

            @log << "merge_minor #{minor.name} "

            if minor.name == "大軌"
              merge_minor!(minor, corporation, source)
              @kintetsu_special_operating = true
              corporation.floatable = true #Kintetsu floats when president share is bought
              initialCapital = corporation.par_price.price * 4
              @bank.spend(initialCapital, corporation)
              @log << "#{corporation.name} floats with #{initialCapital} (par_price *4)"

              hantetsu = @minors.find { |m| m.name == "阪鉄" }
              exchange_share(hantetsu, reserved_kintetsu_shares(corporation).first.to_bundle)
              merge_minor!(hantetsu, corporation, source)
              @round.recalculate_order_when_merge_Kintetsu if @round.respond_to?(:recalculate_order_when_merge_Kintetsu)
              hantetsu_private = @companies.find { |c| c.sym == "阪鉄" }
              hantetsu_private.close!
            else
              exchange_share(minor, bundle)
              if minor.name == '河南'
                refund = minor.cash / 2
                minor.spend(refund, minor.owner)
                @log << "#{minor.owner.name} receives #{format_currency(refund)} from #{minor.name}"
              end
              merge_minor!(minor, corporation, source)
            end
            privateOfMinor = @companies.find { |c| c.sym == minor.name }
            privateOfMinor.close!


          end
        def merge_minor!(minor, corporation, source)
          transfer_treasury(minor, corporation)
          transfer_trains(minor, corporation)
          minor.placed_tokens.each do |token|
            transfer_minor_token!(token, corporation) 
          end


          close_corporation(minor, quiet: false) 
          minor.close! 
        end

        def tile_lays(entity)
          return EXTRA_TILE_LAYS if abilities(entity, :extra_tile_lay)

          super
        end


        def transfer_minor_token!(token, corporation)
            minor = token.corporation
            city = token.city
            coord = city.hex.coordinates
            token.remove!
            token_to_place = corporation.unplaced_tokens.find { |t| t.price != 40 }# first cost is 40 so 40 token must be reserved
            city.place_token(corporation, token_to_place || corporation.next_token, check_tokenable: false)
            return unless minor.assigned?(coord)

            minor.remove_assignment!(coord)
            corporation.assign!(coord)
        end

        def transfer_trains(source, destination)
          return unless source.trains.any?

          transferred = []
          if destination == @depot
            source.trains.dup.each do |train|
              @depot.reclaim_train(train)
              transferred << train
            end
          else
            transferred = transfer(:trains, source, destination)
          end

          if destination.respond_to?(:id) && destination.id == '近鉄'
            transferred.each { |train| train.operated = false }
          end

          @log << "#{destination.name} takes #{transferred.map(&:name).join(', ')}"\
                       " train#{transferred.one? ? '' : 's'} from #{source.name}"

        end

      def event_close_companies!
        @log << '-- Event: Private companies close --'
        @companies.each do |company|
          next unless company.type == :private
          next if %w[市電 神電].include?(company.id)

          if (ability = abilities(company, :close, on_phase: 'any')) &&
              (ability.on_phase == 'never' || @phase.future.any? { |phase| ability.on_phase == phase[:name] })
            next
          end

          company.close!
        end
      end

        def transfer_treasury(source, destination)
          return unless source.cash.positive?

          @log << "#{destination.name} takes #{format_currency(source.cash)}"\
                       " from #{source.name} remaining cash"

          source.spend(source.cash, destination)
        end


        def exchange_share(minor, bundle)
          corporation = bundle.corporation

          @log << "#{minor.owner.name} exchanges #{minor.name} for a "\
                       "#{bundle.percent}% share of #{corporation.name}"

          @share_pool.buy_shares(minor.owner, bundle, exchange: true)

        end

        def reserved_kintetsu_shares(corporation)
          corporation.treasury_shares.reject(&:buyable)
        end

        def release_reserved_kintetsu_shares!(corporation)
          reserved_kintetsu_shares(corporation).each { |share| share.buyable = true }
        end



      end
    end
  end
end
