# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::Entities do
  it 'defines all twelve Long Game Minor Companies and six Major Corporations' do
    expect(described_class::MINOR_COMPANIES.map { |company| company[:name] }).to contain_exactly(
      'Spacious', 'Adaptive', 'Bridging', 'Overnight', 'Tunneling', 'Resourceful',
      'Eastern Mining', 'Agricultural', 'Northern Port', 'Expansive', 'Express', 'Suburban'
    )
    expect(described_class::MAJOR_CORPORATIONS.map { |corporation| corporation[:name] }).to contain_exactly(
      'Consortium', 'Union', 'System', 'International', 'Federation', 'Experiment'
    )
  end

  it 'uses the printed share and hub-token structures' do
    expect(described_class::MINOR_SHARES).to eq([40, 20, 20, 20])
    expect(described_class::MAJOR_SHARES).to eq([20, 10, 10, 10, 10, 10, 10, 10, 10])
    expect(described_class::MINOR_TOKENS).to eq([0])
    expect(described_class::MAJOR_TOKENS).to eq([0, 0, 60, 80])
    expect(described_class::CORPORATIONS).to all(satisfy { |corporation| corporation[:shares].sum == 100 })
  end

  it 'assigns one stable ability identity to every Minor Company' do
    expect(described_class::ABILITY_BY_MINOR.size).to eq(12)
    expect(described_class::ABILITY_BY_MINOR.values.uniq.size).to eq(12)
    expect(described_class::ABILITY_BY_MINOR).to include(
      'SPA' => :spacious,
      'ADA' => :adaptive,
      'XPN' => :expansive,
      'XPR' => :express,
    )
  end

  it 'keeps the four printed Short Game exclusions explicit without removing them from Long Game data' do
    expect(described_class::SHORT_GAME_EXCLUSIONS).to contain_exactly('ADA', 'OVN', 'BRI', 'SPA')
    expect(described_class::MINOR_COMPANIES.map { |company| company[:sym] })
      .to include(*described_class::SHORT_GAME_EXCLUSIONS)
  end

  it 'can construct real engine corporations before map homes are attached' do
    entities = described_class::CORPORATIONS.map do |definition|
      Engine::Corporation.new(**definition.reject { |key| key == :ability_id })
    end

    expect(entities.size).to eq(18)
    expect(entities.count { |corporation| corporation.type == :minor }).to eq(12)
    expect(entities.reject { |corporation| corporation.type == :minor }.map { |corporation| corporation.tokens.map(&:price) })
      .to all(eq([0, 0, 60, 80]))
  end
end
