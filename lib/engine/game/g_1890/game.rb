# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/special_track'
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

        STARTING_CASH = { 2 => 1260, 3 => 840, 4 => 1000, 5 => 504, 6 => 420, 7 => 360}.freeze

        CAPITALIZATION = :full

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
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: 'D',
            on: 'D',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
        ].freeze

        TRAINS = [
          {
            name: '2',
            distance: 2,
            price: 80,
            rusts_on: '4',
            num: 1,
          },
          {
            name: '2-2',
            distance: [{ 'nodes' => ['town'], 'pay' => 2, 'visit' => 2 },
                       { 'nodes' => %w[city offboard town], 'pay' => 2, 'visit' => 2 }],
            price: 120,
            rusts_on: '5',
            num: 1,
          },
          {
            name: '3',
            distance: 3,
            price: 180,
            rusts_on: '6',
            num: 1,
          },
          {
            name: '3-3',
            distance: [{ 'nodes' => ['town'], 'pay' => 3, 'visit' => 3 },
                       { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 }],
            price: 230,
            rusts_on: '6',
            num: 1,
            events: [{ 'type' => 'conversion_to_Kintetsu' }],
          },
          {
            name: '4',
            distance: 4,
            price: 300,
            rusts_on: 'D',
            num: 1,
            events: [{ 'type' => 'kanan_merge_to_Kintetsu' }],
          },
          {
            name: '5',
            distance: 5,
            price: 450,
            num: 1,
            events: [{ 'type' => 'close_companies' },
                     { 'type' => 'remove_extra_tile_lay_from_JR' },],
          },
          { name: '6', distance: 6, price: 630, num: 2,
            events: [{ 'type' => 'Osaka_Expo' }],
          },
          {
            name: 'D',
            distance: 999,
            price: 1100,
            num: 'unlimited',
            available_on: '6',
            discount: { '4' => 300, '5' => 300, '6' => 300 },
          },
].freeze
        @Osaka_Expo_timing = false
        EBUY_PRES_SWAP = false # allow presidential swaps of other corps when ebuying
        EBUY_FROM_OTHERS = :never # allow ebuying other corp trains for up to face
        HOME_TOKEN_TIMING = :operating_round
        EXTRA_TILE_LAYS = [{ lay: true, upgrade: true },
                           { lay: true, upgrade: true, cannot_reuse_same_hex: true },].freeze

        INITIAL_AUCTION_ORDER = %w[有電 神電 堺電 阪国 京津 市電 河南 大軌 阪鉄 奈良 神戸].freeze

        EVENTS_TEXT = Base::EVENTS_TEXT.dup.merge(
          'conversion_to_Kintetsu' => ['近鉄への強制転換', '大阪電気軌道がまだ近鉄に転換していなければ、強制転換（大阪鉄道も合併）'],
          'remove_extra_tile_lay_from_JR' => ['JRの2タイル配置終了', 'JRは、ここまでは2か所でタイル配置できる'],
          'kanan_merge_to_Kintetsu' => ['河南の強制合併', '近鉄開始以降合併可だが、このタイミングで強制合併'],
          'Osaka_Expo' => ['万博(1970)', '北大阪急行が一度だけ40の追加配当を行う'],
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
          @minors.each {|m| place_home_token(m)}
          jr = @corporations.find{|c| c.name == 'JR'}
          jr.add_ability(Engine::Ability::Base.new(
            type: 'extra_tile_lay',# entityでこの能力を記述すると、対応する能力クラスがなくて落ちる
          ))

        end

        def initial_auction_companies
          INITIAL_AUCTION_ORDER.map { |id| @companies.find { |company| company.id == id } }
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
            Engine::Step::Token,
            Engine::Step::Route,
            G1890::Step::Dividend,
            Engine::Step::DiscardTrain,
            G1890::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
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
                @log << "近鉄 share num: #{shares.size} "
                shares[4].buyable = false
                shares[5].buyable = false
                shares[6].buyable = false
                shares[7].buyable = false

              end
            }

            @companies.each { |c| @log << "is #{c.type} " }
            @log << "add latecomercompany. size: #{@latecomer_companies.size} "
            @companies += @latecomer_companies
            @log << "added latecomercompany. size: #{@companies.size} "
            @log << "buyable_bank_owned_companies size: #{buyable_bank_owned_companies.size} "
            @log << "unclosed_companies size: #{@latecomer_companies.select { |c| !c.closed? }.size} "
            @log << "corps size: #{@corporations.size} "

            update_cache(:companies)
          end

          super
        end

        def unowned_purchasable_companies(_entity)
          @companies.select { |c| !c.owned_by_player? }
        end

        def place_home_token(corporation)
          return super unless corporation.name == "JR"
          return if corporation.tokens.first&.used
          Array(corporation.coordinates).each do |coord|
            hex = hex_by_id(coord)
            tile = hex&.tile
            cities = tile.cities
            city = cities.find { |c| c.reserved_by?(corporation) } || cities.first
            token = corporation.find_token_by_type

            @log << "#{corporation.name} places a token on #{hex.name}"
            city.place_token(corporation, token)
          end
            abilities = corporation.all_abilities.select { |ability| ability.type == :reservation}
            abilities.each { |r| 
            hex = hex_by_id(r.hex)
            @log << "#{corporation.name} places a token on #{hex.name}"

            tile = hex&.tile
            cities = tile.cities
            city = cities[r.city]
            token = corporation.find_token_by_type
            city.place_token(corporation, token)
            corporation.remove_ability(r) 
          }

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
        exchange_minor(kanan,kintetsu.shares[6].to_bundle)
      end

      def event_remove_extra_tile_lay_from_JR!
        jr = @corporations.find{|c| c.name == 'JR'}
        jr.remove_ability(jr.all_abilities.find { |ability| ability.type == :extra_tile_lay})
      end

      def event_Osaka_Expo!
        @Osaka_Expo_timing = true
      end



      def payout_companies(ignore: [])
        companies = companies_to_payout(ignore: ignore)

        companies.sort_by! do |company|
          [
            company.owned_by_player? ? [0, @players.index(company.owner)] : [1, company.owner],
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
              @log << "#{keihan.name} have token in 堺, so collects 40 from 泉北"
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
      end


      def after_buy_company(player, company, _price)
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

        def acquire_minor(company)
          return unless (minor = @minors.find { |m| m.name == company.sym })
          minor.owner = company.player
          @bank.spend(company.treasury, minor)
          minor.float!
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

          def exchange_minor(minor, bundle)
            corporation = bundle.corporation
            source = bundle.owner
            # unless can_gain?(minor.owner, bundle, exchange: true)
            #   raise GameError, "#{minor.name} cannot be exchanged for #{corporation.name}"
            # end

            @log << "merge_minor #{minor.name} "

            if minor.name == "大軌"
              merge_minor!(minor, corporation, source)
              corporation.floatable = true #Kintetsu floats when president share is bought
              initialCapital = corporation.par_price.price * 4
              @bank.spend(initialCapital, corporation)
              @log << "#{corporation.name} floats with #{initialCapital} (par_price *4)"

              hantetsu = @minors.find { |m| m.name == "阪鉄" }
              exchange_share(hantetsu, corporation, source)
              merge_minor!(hantetsu, corporation, source)
              @round.recalculate_order_when_merge_Kintetsu if @round.respond_to?(:recalculate_order_when_merge_Kintetsu)
              hantetsu_private = @companies.find { |c| c.sym == "阪鉄" }
              hantetsu_private.close!
            else
              exchange_share(minor, corporation, source)
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
            city.place_token(corporation, corporation.next_token, check_tokenable: false)
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

          @log << "#{destination.name} takes #{transferred.map(&:name).join(', ')}"\
                       " train#{transferred.one? ? '' : 's'} from #{source.name}"

        end

      def event_close_companies!
        @log << '-- Event: Private companies close --'
        @companies.each do |company|
          if (ability = abilities(company, :close, on_phase: 'any')) &&
              (ability.on_phase == 'never' || @phase.future.any? { |phase| ability.on_phase == phase[:name] })
            next
          end
          if company.type == :latecomer
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


        def exchange_share(minor, corporation, source)
          return unless corporation

          @log << "#{minor.owner.name} exchanges #{minor.name} for a "\
                       "10% share of #{corporation.name}"

          bundle = if source == corporation
                     corporation.treasury_shares.first.to_bundle
                   else
                     @share_pool.shares_of(corporation).first.to_bundle
                   end

                  @share_pool.buy_shares(minor.owner,
                                    bundle,
                                    exchange: true)

        end



      end
    end
  end
end
