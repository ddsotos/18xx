# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::GameData do
  it 'uses the complete thirty-card four-player Long Game train roster' do
    expect(described_class::TRAIN_COUNTS).to eq(
      '2' => 7,
      '3' => 6,
      '4' => 4,
      '5' => 3,
      '6' => 3,
      '7' => 7,
    )
    expect(described_class::TRAINS.sum { |train| train[:num] }).to eq(30)
  end

  it 'matches the printed train prices and rust events' do
    trains = described_class::TRAINS.to_h { |train| [train[:name], train] }
    expect(trains.transform_values { |train| train[:price] }).to eq(
      '2' => 100,
      '3' => 200,
      '4' => 300,
      '5' => 450,
      '6' => 550,
      '7' => 750,
    )
    expect(trains.transform_values { |train| train[:rusts_on] }.compact).to eq(
      '2' => '4',
      '3' => '6',
      '4' => '7',
    )
    expect(trains.fetch('7').fetch(:variants).first).to include(name: '∞', distance: 99, price: 1000)
  end

  it 'changes train limits and tile colors at the printed thresholds' do
    phases = described_class::PHASES.to_h { |phase| [phase[:name], phase] }
    expect(phases.transform_values { |phase| phase[:train_limit] }).to eq(
      '2' => { minor: 2, major: 0 },
      '3' => { minor: 2, major: 4 },
      '4' => { minor: 2, major: 3 },
      '5' => { minor: 1, major: 2 },
      '6' => { minor: 1, major: 2 },
      '7' => { minor: 1, major: 2 },
    )
    expect(phases.fetch('3')[:tiles]).to eq(%i[yellow green])
    expect(phases.fetch('5')[:tiles]).to eq(%i[yellow green purple])
    expect(phases.fetch('7')[:tiles]).to eq(%i[yellow green purple gray])
  end

  it 'exposes only the supported four-player starting capital' do
    expect(described_class::STARTING_CASH).to eq(4 => 275)
  end

  it 'marks the complete launch range as par without adding higher gray values' do
    par_prices = described_class::MARKET.flatten.grep(/p/).map(&:to_i)
    expect(par_prices).to eq([60, 70, 80, 90, 100, 110, 120, 135])
    expect(described_class::MARKET.flatten.last).to eq('500')
  end
end
