# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Step::LeadoffTrain do
  let(:game_class) do
    allow_obsolete_train_buy = false

    Class.new do
      const_set(:ALLOW_OBSOLETE_TRAIN_BUY, allow_obsolete_train_buy)

      attr_reader :bank, :depot, :log, :phase

      def initialize(corporation, trains)
        @corporation = corporation
        @log = []
        @bank = Engine::Bank.new(10_000, log: @log)
        @depot = Engine::Depot.new(trains, self)
        @phase = Object.new
        @phase.define_singleton_method(:buying_train!) { |_entity, _train, _source| }
        @operated = false
      end

      def rotla_corporation_operated?(_corporation)
        @operated
      end

      def operated!
        @operated = true
      end

      def num_corp_trains(corporation)
        corporation.trains.size
      end

      def train_limit(_corporation)
        2
      end

      def buy_train(operator, train, price)
        operator.spend(price, train.owner)
        depot.remove_train(train)
        train.owner = operator
        operator.trains << train
      end

      def format_currency(amount)
        "#{amount}金"
      end
    end
  end

  let(:round_class) do
    Struct.new(:entities, :entity_index)
  end

  def build_step(cash: 140)
    definition = Engine::Game::GRotLA::Entities::MINOR_COMPANIES.first
    corporation = Engine::Corporation.new(**definition.reject { |key| key == :ability_id })
    trains = [
      Engine::Train.new(name: '2', distance: 2, price: 100, index: 0),
      Engine::Train.new(name: '3', distance: 3, price: 200, index: 0),
    ]
    game = game_class.new(corporation, trains)
    game.bank.spend(cash, corporation)
    step = described_class.new(game, round_class.new([corporation], 0))
    step.setup
    [step, game, corporation, trains]
  end

  it 'offers one optional affordable depot train before the first operation' do
    step, _game, corporation, trains = build_step

    expect(step.actions(corporation)).to eq(%w[buy_train pass])
    expect(step.buyable_trains(corporation)).to eq([trains[0]])
    expect(step.buyable_train_variants(trains[0], corporation).map { |variant| variant[:name] }).to eq(['2'])
  end

  it 'pays only company cash at face value and completes after one purchase' do
    step, game, corporation, trains = build_step
    bank_cash = game.bank.cash

    step.process_buy_train(Engine::Action::BuyTrain.new(corporation, train: trains[0], price: 100))

    expect(corporation.cash).to eq(40)
    expect(corporation.trains).to eq([trains[0]])
    expect(game.bank.cash).to eq(bank_cash + 100)
    expect(step).to be_passed
  end

  it 'allows passing and does not appear after the company has operated' do
    step, game, corporation, = build_step

    step.process_pass(Engine::Action::Pass.new(corporation))
    expect(step).to be_passed

    step.unpass!
    game.operated!
    expect(step.actions(corporation)).to be_empty
  end

  it 'rejects other-company trains, non-face prices, unaffordable trains, and modifiers before mutation' do
    step, game, corporation, trains = build_step
    other = Engine::Corporation.new(sym: 'OTH', name: 'Other', shares: [100], tokens: [])
    other_train = Engine::Train.new(name: '2', distance: 2, price: 100)
    other_train.owner = other
    other.trains << other_train
    before = [corporation.cash, corporation.trains.dup, game.depot.upcoming.dup]

    [
      Engine::Action::BuyTrain.new(corporation, train: other_train, price: 100),
      Engine::Action::BuyTrain.new(corporation, train: trains[0], price: 90),
      Engine::Action::BuyTrain.new(corporation, train: trains[1], price: 200),
      Engine::Action::BuyTrain.new(corporation, train: trains[0], price: 100, exchange: trains[1]),
    ].each do |action|
      expect { step.process_buy_train(action) }.to raise_error(Engine::GameError)
      expect([corporation.cash, corporation.trains, game.depot.upcoming]).to eq(before)
    end
  end
end
