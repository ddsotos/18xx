# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::MapBuilder do
  let(:data) do
    {
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
        'placements' => [{ 'copy_id' => 'piece', 'origin' => [-4, 2], 'rotation' => 1 }],
      },
    }
  end
  let(:config) { Engine::Game::GRotLA::SetupConfig.new(data) }
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
        {
          'axial' => [0, 1],
          'color' => 'white',
          'code' => 'border=edge:5,type:impassable;stub=edge:4',
          'city_type' => nil,
        },
      ],
    }
  end
  let(:builder) { described_class.new(config, catalog: catalog) }

  it 'compiles into the Base hex format and rotates real paths before graph initialization' do
    map = builder
    harness = Class.new(Engine::Game::G1889::Game) do
      define_method(:game_hexes) { map.game_hexes }
      define_method(:init_companies) { |_players| [] }
      define_method(:init_corporations) { |_market| [] }
      define_method(:init_hexes) { |companies, corporations| map.apply_rotations!(super(companies, corporations)) }
    end
    game = harness.new(%w[a b c d], seed: 123)
    expect(game.hexes.size).to eq(3)
    cities = game.hexes.select { |hex| hex.tile.cities.any? }
    expect(cities.map { |hex| hex.tile.exits }).to eq([[0], [3]])
    expect(cities.first.neighbors[0]).to equal(cities.last)
    expect(cities.last.neighbors[3]).to equal(cities.first)
    expect(game.graph).to be_a(Engine::Graph)
    expect(game.hexes.last.tile.borders.first.edge).to eq(0)
    expect(game.hexes.last.tile.stubs.first.edge).to eq(5)
  end

  it 'detaches catalog data and each returned hex definition' do
    expected = builder.game_hexes
    catalog['piece'][0]['code'] = 'city=revenue:999'
    exported = builder.game_hexes
    exported[:yellow].values.first.replace('city=revenue:999')
    expect(builder.game_hexes).to eq(expected)
  end

  it 'resolves rotated city classifications to the constructed Engine cities' do
    map = builder
    harness = Class.new(Engine::Game::G1889::Game) do
      define_method(:game_hexes) { map.game_hexes }
      define_method(:init_companies) { |_players| [] }
      define_method(:init_corporations) { |_market| [] }
      define_method(:init_hexes) { |companies, corporations| map.apply_rotations!(super(companies, corporations)) }
    end
    game = harness.new(%w[a b c d], seed: 123)

    expect(map.cities_by_type(game, :basic)).to eq([game.hexes[0].tile.cities.first])
    expect(map.cities_by_type(game, :capital)).to eq([game.hexes[1].tile.cities.first])
    expect(map.cities_by_type(game, :company)).to eq([])

    upgraded = Engine::Tile.for('14', index: 99)
    game.hexes[0].tile = upgraded
    expect(map.cities_by_type(game, :basic)).to eq(upgraded.cities)
  end

  it 'requires an explicit legal classification for every city' do
    catalog['piece'][0].delete('city_type')
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /classify each city hex/)

    catalog['piece'][0]['city_type'] = 'unknown'
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /classify each city hex/)

    catalog['piece'][0]['city_type'] = 'basic'
    catalog['piece'][2]['city_type'] = 'basic'
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /classify each city hex/)
  end

  it 'rejects missing and unused physical copies' do
    expect { described_class.new(config, catalog: {}) }.to raise_error(ArgumentError, /every catalog copy/)
    catalog['unused'] = catalog['piece']
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /every catalog copy/)
  end

  it 'rejects overlapping placements across distinct physical copies' do
    data['map_manifest']['placements'] << data['map_manifest']['placements'][0].merge('copy_id' => 'second')
    catalog['second'] = catalog['piece']
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /distinct/)
  end

  it 'rejects unresolved project effects instead of dropping them from the map' do
    data['map_manifest']['projects'] << {
      'project_copy_id' => 'capital', 'target_city_id' => 'city', 'effect_type' => 'capital'
    }
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /not implemented/)
  end

  it 'requires a three-hex definition and validates all rotation targets before mutation' do
    catalog['piece'].pop
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /three hexes/)
  end

  it 'rejects mismatched engine hexes before applying rotations' do
    hex = Engine::Hex.new('Z99', layout: :flat)
    expect { builder.apply_rotations!([hex]) }.to raise_error(ArgumentError, /do not match/)
    expect(hex.tile.rotation).to eq(0)
  end

  it 'rejects rotated partitions until their vertex geometry is implemented' do
    catalog['piece'][0]['code'] = 'partition=a:0,b:3,type:water'
    catalog['piece'][0]['city_type'] = nil
    expect { described_class.new(config, catalog: catalog) }.to raise_error(ArgumentError, /partition geometry/)
  end
end
