# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::FoundingAuction do
  let(:columns) { [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]] }

  let(:game_class) do
    Class.new do
      attr_reader :players, :corporations, :stock_market, :share_pool, :phase, :log, :rotla_setup_config, :bank

      def initialize(columns, colors: [:yellow])
        @log = []
        @players = %w[p1 p2 p3 p4].map { |id| Engine::Player.new(id, id.upcase) }
        @bank = Engine::Bank.new(10_000, log: @log)
        @players.each { |player| @bank.spend(275, player) }
        @corporations = Engine::Game::GRotLA::Entities::MINOR_COMPANIES.map do |definition|
          Engine::Corporation.new(**definition.reject { |key| key == :ability_id })
        end
        @stock_market = Engine::StockMarket.new(Engine::Game::GRotLA::GameData::MARKET, [])
        @share_pool = Engine::SharePool.new(self)
        @phase = Struct.new(:tiles).new(colors)
        @rotla_setup_config = Struct.new(:data) { def to_h = data }.new({ 'minor_tableau' => columns })
      end

      def corporation_by_id(id)
        @corporations.find { |corporation| corporation.id == id }
      end

      def format_currency(amount)
        "#{amount}金"
      end
    end
  end

  let(:round_class) do
    Class.new do
      attr_reader :entities
      attr_accessor :entity_index, :pending_adaptive_home

      def initialize(entities, entity_index: 0)
        @entities = entities
        @entity_index = entity_index
      end

      def goto_entity!(entity)
        @entity_index = @entities.index(entity)
      end
    end
  end

  def build_step(colors: [:yellow], entity_index: 0)
    game = game_class.new(columns, colors: colors)
    round = round_class.new(game.players, entity_index: entity_index)
    step = described_class.new(game, round)
    step.setup
    [step, game, round]
  end

  def resolve_for(step, game, initiator_index:, bid:, company_id:)
    players = game.players
    initiator = players[initiator_index]
    step.process_bid(Engine::Action::Bid.new(initiator, price: bid))
    players.rotate(initiator_index + 1).first(players.size - 1).each do |player|
      step.process_pass(Engine::Action::Pass.new(player))
    end
    step.process_choose(Engine::Action::Choose.new(initiator, choice: company_id))
  end

  it 'starts only from a targetless Bid action and then blocks the stock turn' do
    step, game, = build_step
    player = game.players.first
    expect(step.blocks?).to be(false)
    expect(step.actions(player)).to eq(['bid'])

    action = Engine::Action::Bid.new(player, price: 120)
    expect(action.company).to be_nil
    step.process_bid(action)
    expect(step.blocks?).to be(true)
    expect(step.active_entities).to eq([game.players[1]])
    expect(step.actions(game.players[1])).to eq(%w[bid pass])
  end

  it 'rejects an unaffordable raise without changing auction state' do
    step, game, = build_step
    step.process_bid(Engine::Action::Bid.new(game.players[0], price: 120))
    before = step.auction_state.to_h
    expect { step.process_bid(Engine::Action::Bid.new(game.players[1], price: 280)) }
      .to raise_error(Engine::GameError, /cannot afford/)
    expect(step.auction_state.to_h).to eq(before)
  end

  it 'settles the full bid into treasury and transfers only the 40% president share' do
    step, game, round = build_step
    resolve_for(step, game, initiator_index: 0, bid: 165, company_id: 'SPA')
    player = game.players[0]
    corporation = game.corporation_by_id('SPA')

    expect(player.cash).to eq(110)
    expect(corporation.cash).to eq(165)
    expect(player.percent_of(corporation)).to eq(40)
    expect(corporation.percent_of(corporation)).to eq(60)
    expect(corporation.owner).to eq(player)
    expect(corporation.share_price.price).to eq(80)
    expect(corporation).to be_floated
    expect(round.entity_index).to eq(1)
    expect(step.minor_tableau.front_ids).to eq(%w[ADA TUN NP])
    expect(step.blocks?).to be(false)
  end

  it 'applies the phase-specific launch price ceiling' do
    [
      [[:yellow], 200, 90],
      [%i[yellow green], 220, 110],
      [%i[yellow green purple], 270, 135],
      [%i[yellow green purple gray], 275, 135],
    ].each do |colors, bid, expected|
      step, game, = build_step(colors: colors)
      resolve_for(step, game, initiator_index: 0, bid: bid, company_id: 'SPA')
      expect(game.corporation_by_id('SPA').share_price.price).to eq(expected)
    end
  end

  it 'leaves cash, shares, market, and tableau unchanged after an invalid choice' do
    step, game, = build_step
    step.process_bid(Engine::Action::Bid.new(game.players[0], price: 120))
    game.players.drop(1).each { |player| step.process_pass(Engine::Action::Pass.new(player)) }
    corporation = game.corporation_by_id('ADA')
    before = [game.players[0].cash, corporation.cash, corporation.percent_of(corporation), step.minor_tableau.snapshot]

    expect { step.process_choose(Engine::Action::Choose.new(game.players[0], choice: 'ADA')) }
      .to raise_error(Engine::GameError, /not available/)
    expect([game.players[0].cash, corporation.cash, corporation.percent_of(corporation), step.minor_tableau.snapshot])
      .to eq(before)
    expect(corporation.share_price).to be_nil
  end

  it 'returns to the player after the initiator even when another player wins' do
    step, game, round = build_step(entity_index: 1)
    players = game.players
    step.process_bid(Engine::Action::Bid.new(players[1], price: 120))
    step.process_bid(Engine::Action::Bid.new(players[2], price: 125))
    step.process_pass(Engine::Action::Pass.new(players[3]))
    step.process_pass(Engine::Action::Pass.new(players[0]))
    step.process_pass(Engine::Action::Pass.new(players[1]))
    step.process_choose(Engine::Action::Choose.new(players[2], choice: 'TUN'))

    expect(game.corporation_by_id('TUN').owner).to eq(players[2])
    expect(round.entity_index).to eq(2)
  end

  it 'appends a newly founded company below an existing token at the same price' do
    step, game, round = build_step
    resolve_for(step, game, initiator_index: 0, bid: 120, company_id: 'SPA')
    round.entity_index = 1
    resolve_for(step, game, initiator_index: 1, bid: 120, company_id: 'TUN')
    price = game.stock_market.par_prices.find { |share_price| share_price.price == 60 }
    expect(price.corporations.map(&:id)).to eq(%w[SPA TUN])
  end

  it 'defers Adaptive home placement after financial settlement' do
    step, game, = build_step
    resolve_for(step, game, initiator_index: 0, bid: 120, company_id: 'SPA')
    resolve_for(step, game, initiator_index: 1, bid: 120, company_id: 'ADA')
    expect(step.pending_adaptive_home).to eq(game.corporation_by_id('ADA'))
  end
end
