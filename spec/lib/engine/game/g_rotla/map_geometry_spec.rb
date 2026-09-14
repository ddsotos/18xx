# frozen_string_literal: true

require 'spec_helper'

describe Engine::Game::GRotLA::MapGeometry do
  it 'rotates axial coordinates through known orientations and a complete cycle' do
    expected = [[2, -1], [1, 1], [-1, 2], [-2, 1], [-1, -1], [1, -2]]
    expect((0..5).map { |turns| described_class.rotate([2, -1], turns) }).to eq(expected)
    point = 6.times.reduce([2, -1]) { |value, _| described_class.rotate(value) }
    expect(point).to eq([2, -1])
  end

  it 'keeps direction vectors consistent with positive rotation and opposite directions' do
    directions = described_class::DIRECTIONS
    directions.each_with_index do |point, index|
      expect(described_class.rotate(point)).to eq(directions[(index + 1) % 6])
      expect(described_class.rotate(point, 3)).to eq(point.map { |value| -value })
    end
  end

  it 'rotates before translating and leaves mutable input arrays unfrozen' do
    source = [[0, 0], [1, 0]]
    origin = [3, -2]
    result = described_class.transform(source, origin: origin, rotation: 1)
    expect(result).to eq([[3, -2], [3, -1]])
    expect(source).to eq([[0, 0], [1, 0]])
    expect(source).not_to be_frozen
    expect(source.first).not_to be_frozen
    expect(origin).not_to be_frozen
    expect(result).to be_frozen
    expect(result.first).to be_frozen
  end

  it 'returns a detached coordinate for zero rotation' do
    point = [2, -1]
    result = described_class.rotate(point, 0)
    expect(point).not_to be_frozen
    expect(result).not_to equal(point)
    point[0] = 99
    expect(result).to eq([2, -1])
  end

  it 'counts two and three boundary edges across distinct existing hexes' do
    existing = [[0, 0], [1, 0]]
    expect(described_class.shared_edges(existing, [[0, 1]])).to eq(2)
    expect(described_class.shared_edges(existing, [[0, 1], [1, 1]])).to eq(3)
    expect(described_class.shared_edges([[0, 1], [1, 1]], existing)).to eq(3)
    expect(described_class.shared_edges(existing, [[3, 0]])).to eq(0)
    expect(described_class.shared_edges([], existing)).to eq(0)
  end

  it 'preserves adjacency under rotation and translation' do
    left = [[0, 0], [1, 0]]
    right = [[0, 1], [1, 1]]
    6.times do |turns|
      a = described_class.transform(left, origin: [-4, 7], rotation: turns)
      b = described_class.transform(right, origin: [-4, 7], rotation: turns)
      expect(described_class.shared_edges(a, b)).to eq(3)
    end
  end

  it 'rejects duplicate coordinates, malformed coordinates and overlapping sets' do
    expect { described_class.transform([[0, 0], [0, 0]]) }.to raise_error(ArgumentError, /distinct/)
    expect { described_class.transform([[0, 0.5]]) }.to raise_error(ArgumentError, /two integers/)
    expect { described_class.shared_edges([[0, 0]], [[0, 0]]) }.to raise_error(ArgumentError, /overlap/)
    expect(described_class.overlap?([[0, 0]], [[1, 0]])).to be(false)
    expect(described_class.overlap?([[0, 0]], [[0, 0]])).to be(true)
  end

  [-1, 6, '1', nil].each do |turns|
    it "rejects unsupported rotation #{turns.inspect}, even for an empty tile" do
      expect { described_class.rotate([0, 0], turns) }.to raise_error(ArgumentError, /rotation/)
      expect { described_class.transform([], rotation: turns) }.to raise_error(ArgumentError, /rotation/)
    end
  end
end
