# frozen_string_literal: true

require './spec/spec_helper'
require './lib/engine/game/g_rotla/map'

describe Engine::Game::GRotLA::TrackTiles do
  def build_tile(tile_id)
    definition = described_class::TILES.fetch(tile_id)
    Engine::Tile.from_code(tile_id, definition.fetch('color'), definition.fetch('code'))
  end

  it 'vectorizes every physical tile type without changing inventory counts' do
    expect(described_class::TILES.keys).to match_array(described_class::MANIFEST_IDS)
    expect(described_class::TILES.sum { |_id, tile| tile.fetch('count') }).to eq(135)
    expect(Engine::Game::GRotLA::Map::TILES).to equal(described_class::TILES)
  end

  it 'decodes every non-city path pairing exactly as traced' do
    described_class::PATH_SPECS.each do |tile_id, expected_paths|
      actual_paths = build_tile(tile_id).paths.map { |path| path.exits.sort }
      expect(actual_paths).to match_array(expected_paths.map(&:sort)), tile_id
    end
  end

  it 'decodes every city as one city with the printed revenue, slots, exits, and symbol family' do
    described_class::CITY_SPECS.each do |tile_id, (revenue, slots, exits, special)|
      tile = build_tile(tile_id)

      expect(tile.cities.size).to eq(1), tile_id
      expect(tile.cities.first.revenue.values.uniq).to eq([revenue]), tile_id
      expect(tile.cities.first.normal_slots).to eq(slots), tile_id
      expect(tile.exits).to match_array(exits), tile_id
      expected_label = special && described_class::SPECIAL_LABELS.fetch(special)
      expect(tile.label&.to_s).to eq(expected_label), tile_id
    end
  end

  it 'keeps bridge geometry identical to the three yellow base tracks' do
    expect(described_class::PATH_SPECS.values_at('RLA-B01', 'RLA-B02', 'RLA-B03')).to eq(
      described_class::PATH_SPECS.values_at('RLA-Y01', 'RLA-Y07', 'RLA-Y08'),
    )
  end
end
