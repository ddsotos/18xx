# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::FixedMap do
  let(:catalog) do
    {
      'piece' => [
        { 'axial' => [0, 0], 'color' => 'yellow', 'code' => 'city=revenue:20;path=a:5,b:_0' },
        { 'axial' => [1, 0], 'color' => 'yellow', 'code' => 'city=revenue:30;path=a:2,b:_0' },
        { 'axial' => [0, 1], 'color' => 'white', 'code' => '' },
      ],
    }
  end
  let(:settings) do
    {
      'rotla' => {
        'schema_version' => 1,
        'ruleset' => 'en-second-printing',
        'mode' => 'long',
        'player_count' => 4,
        'map_manifest_version' => 1,
        'map_id' => 'synthetic',
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
  end

  it 'rebuilds the same map through clone and Action replay' do
    game = build_game_class(catalog).new(%w[a b c d], settings: settings, seed: 123, strict: true)
    game.process_action(Engine::Action::Pass.new(game.current_entity)).maybe_raise!
    copy = game.clone(game.raw_actions)
    expect(copy.hexes.map(&:coordinates)).to eq(game.hexes.map(&:coordinates))
    expect(copy.hexes.map { |hex| hex.tile.exits }).to eq(game.hexes.map { |hex| hex.tile.exits })
    expect(copy.current_entity.id).to eq(game.current_entity.id)
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
