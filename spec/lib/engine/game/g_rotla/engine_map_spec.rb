# frozen_string_literal: true

require './spec/spec_helper'
require_relative '../../../../../lib/engine/game/g_rotla/map_geometry'
require_relative '../../../../../lib/engine/game/g_rotla/engine_map'

describe Engine::Game::GRotLA::EngineMap do
  it 'maps all six axial directions to the corresponding flat edges' do
    center = [0, 0]
    points = [center] + described_class::AXIAL_DIRECTIONS
    hexes = described_class.build(points)

    described_class::AXIAL_DIRECTIONS.each do |direction|
      neighbor = hexes[direction]
      expect(hexes[center].neighbor_direction(neighbor)).to eq(described_class.edge_for(direction))
      expect(hexes[center].all_neighbors[described_class.edge_for(direction)]).to equal(neighbor)
      expect(neighbor.neighbor_direction(hexes[center])).to eq(Engine::Hex.invert(described_class.edge_for(direction)))
    end
  end

  it 'normalizes negative axial coordinates while retaining doubled-coordinate parity' do
    source = [[-1, 0], [0, 0], [0, 1]]
    hexes = described_class.build(source)

    expect(hexes[[-1, 0]].coordinates).to eq('A1')
    expect(hexes[[0, 0]].coordinates).to eq('B2')
    expect(hexes[[0, 1]].coordinates).to eq('B4')
    hexes.each_value { |hex| expect((hex.x - hex.y).even?).to be(true) }
    expect(source).to eq([[-1, 0], [0, 0], [0, 1]])
    expect(source).not_to be_frozen
  end

  it 'uses spreadsheet-style letters after Z' do
    hexes = described_class.build((0..26).map { |q| [q, 0] })

    expect(hexes[[25, 0]].coordinates).to eq('Z26')
    expect(hexes[[26, 0]].coordinates).to eq('AA27')
  end

  it 'rejects maps wider than Engine::Hex coordinate columns' do
    expect { described_class.coordinates((0..52).map { |q| [q, 0] }) }
      .to raise_error(ArgumentError, /A\.\.AZ/)
  end

  it 'rejects malformed and duplicate axial coordinates' do
    expect { described_class.build([[0, 0], [0, 0]]) }.to raise_error(ArgumentError, /distinct/)
    expect { described_class.build([[0, 0.5]]) }.to raise_error(ArgumentError, /pairs of integers/)
  end
end
