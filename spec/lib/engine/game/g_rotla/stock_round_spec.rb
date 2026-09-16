# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::StockRound do
  let(:game_class) do
    Class.new do
      include Engine::Game::GRotLA::StockRound

      attr_reader :corporations, :log, :rotla_minor_tableau

      def initialize
        @corporations = []
        @log = []
      end
    end
  end

  it 'constructs the RotLA Stock Round with the canonical steps' do
    game = game_class.new
    round = Object.new
    expect(Engine::Game::GRotLA::Round::Stock)
      .to receive(:new)
      .with(game, Engine::Game::GRotLA::StockRoundSteps.steps, round_num: 1)
      .and_return(round)

    expect(game.stock_round).to equal(round)
  end

  it 'marks only the first stock round without a founded company for restart' do
    game = game_class.new
    corporation = Struct.new(:ipoed).new(false)
    game.corporations << corporation
    allow(Engine::Game::GRotLA::Round::Stock).to receive(:new).and_return(Object.new)

    game.stock_round
    expect(game.rotla_restart_initial_stock_round?).to be(true)

    corporation.ipoed = true
    expect(game.rotla_restart_initial_stock_round?).to be(false)

    corporation.ipoed = false
    game.stock_round
    expect(game.rotla_restart_initial_stock_round?).to be(false)
  end

  it 'uses game-seeded randomness to replace the complete Minor tableau' do
    game = game_class.new
    initial = [
      %w[SPA ADA BRI OVN],
      %w[TUN RES EM AGR],
      %w[NP XPN XPR SUB],
    ]
    game.instance_variable_set(:@rotla_minor_tableau, Engine::Game::GRotLA::MinorTableau.new(columns: initial))
    game.define_singleton_method(:rand) { 0 }

    game.rotla_reshuffle_minor_tableau!

    expect(game.rotla_minor_tableau.snapshot).not_to eq(initial)
    expect(game.rotla_minor_tableau.snapshot.flatten)
      .to contain_exactly(*Engine::Game::GRotLA::MinorTableau::COMPANY_IDS)
    expect(game.log.last).to include(*game.rotla_minor_tableau.front_ids)
  end

  it 'hides and disables the engine certificate limit' do
    game = game_class.new

    expect(game.show_game_cert_limit?).to be(false)
    expect(game.cert_limit).to eq(Float::INFINITY)
  end
end
