# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::FixedMap do
  let(:catalog) do
    {
      'piece' => [
        {
          'axial' => [0, 0],
          'color' => 'yellow',
          'code' => 'city=revenue:20;path=a:5,b:_0',
          'city_type' => 'basic',
        },
        {
          'axial' => [1, 0],
          'color' => 'yellow',
          'code' => 'city=revenue:30;path=a:2,b:_0',
          'city_type' => 'capital',
        },
        { 'axial' => [0, 1], 'color' => 'white', 'code' => '', 'city_type' => nil },
      ],
    }
  end
  let(:settings) do
    {
      'rotla' => {
        'schema_version' => 2,
        'ruleset' => 'en-second-printing',
        'mode' => 'long',
        'player_count' => 4,
        'map_manifest_version' => 1,
        'map_id' => 'synthetic',
        'minor_tableau' => [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]],
        'setup_journal' => [],
        'map_manifest' => {
          'map_id' => 'synthetic',
          'map_version' => 1,
          'projects' => [],
          'placements' => [{ 'copy_id' => 'piece', 'origin' => [0, 0], 'rotation' => 1 }],
        },
      },
    }
  end

  def build_game_class(catalog)
    Class.new(Engine::Game::G1889::Game) do
      const_set(:MAP_CATALOG, catalog)
      include Engine::Game::GRotLA::Setup
      include Engine::Game::GRotLA::FixedMap

      define_method(:init_companies) { |_players| [] }
      define_method(:init_corporations) { |_market| [] }
    end
  end

  it 'provides the compiled fixed map throughout real game initialization' do
    game = build_game_class(catalog).new(%w[a b c d], settings: settings, seed: 123)
    expect(game.rotla_map_builder).to be_a(Engine::Game::GRotLA::MapBuilder)
    expect(game.hexes.size).to eq(3)
    cities = game.hexes.select { |hex| hex.tile.cities.any? }
    expect(cities.map { |hex| hex.tile.exits }).to eq([[0], [3]])
    expect(cities.first.neighbors[0]).to equal(cities.last)
    expect(game.graph).to be_a(Engine::Graph)
    expect(game.rotla_adaptive_home_cities(nil)).to eq([cities.first.tile.cities.first])
  end

  it 'rebuilds the same map through clone and Action replay' do
    game = build_game_class(catalog).new(%w[a b c d], settings: settings, seed: 123, strict: true)
    game.process_action(Engine::Action::Message.new(game.players.first, message: 'map replay')).maybe_raise!
    copy = game.clone(game.raw_actions)
    expect(copy.hexes.map(&:coordinates)).to eq(game.hexes.map(&:coordinates))
    expect(copy.hexes.map { |hex| hex.tile.exits }).to eq(game.hexes.map { |hex| hex.tile.exits })
    expect(copy.raw_actions).to eq(game.raw_actions)
  end

  it 'feeds the current basic city through to Adaptive home placement' do
    game = build_game_class(catalog).new(%w[a b c d], settings: settings, seed: 123)
    definition = Engine::Game::GRotLA::Entities::MINOR_COMPANIES.find { |company| company[:sym] == 'ADA' }
    adaptive = Engine::Corporation.new(**definition.reject { |key| key == :ability_id })
    adaptive.owner = game.players.first
    round = Struct.new(:pending_adaptive_home).new(adaptive)
    step = Engine::Game::GRotLA::Step::AdaptiveHome.new(game, round)
    basic_city = game.rotla_adaptive_home_cities(adaptive).first

    expect(step.choices.keys).to eq([basic_city.id])
    step.process_choose(Engine::Action::Choose.new(game.players.first, choice: basic_city.id))

    expect(adaptive.tokens.first.city).to equal(basic_city)
    expect(round.pending_adaptive_home).to be_nil
  end

  it 'fails before Base initialization when the manifest and catalog differ' do
    settings['rotla']['map_manifest']['placements'][0]['copy_id'] = 'unknown'
    expect { build_game_class(catalog).new(%w[a b c d], settings: settings) }
      .to raise_error(ArgumentError, /every catalog copy/)
  end

  it 'requires Setup and a class-local catalog at inclusion time' do
    expect do
      Class.new(Engine::Game::G1889::Game) { include Engine::Game::GRotLA::FixedMap }
    end.to raise_error(ArgumentError, /Setup before/)

    expect do
      Class.new(Engine::Game::G1889::Game) do
        include Engine::Game::GRotLA::Setup
        include Engine::Game::GRotLA::FixedMap
      end
    end.to raise_error(ArgumentError, /MAP_CATALOG/)
  end
end
