# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::MinorTableau do
  let(:columns) { [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]] }

  it 'exposes only the front company in each of three columns' do
    tableau = described_class.new(columns: columns)
    expect(tableau.front_ids).to eq(%w[SPA TUN NP])
    expect(tableau.front?('ADA')).to be(false)
  end

  it 'reveals only the next company in the selected column' do
    tableau = described_class.new(columns: columns)
    expect(tableau.take_front!('TUN')).to eq('TUN')
    expect(tableau.front_ids).to eq(%w[SPA RES NP])
    expect { tableau.take_front!('AGR') }.to raise_error(ArgumentError, /not an available/)
    expect(tableau.front_ids).to eq(%w[SPA RES NP])
  end

  it 'requires every Long Game Minor exactly once and owns its input' do
    tableau = described_class.new(columns: columns)
    columns[0][0] = 'changed'
    expect(tableau.front_ids).to eq(%w[SPA TUN NP])

    invalid = tableau.snapshot
    invalid[0][0] = invalid[1][0]
    expect { described_class.new(columns: invalid) }.to raise_error(ArgumentError, /exactly once/)
  end

  it 'round trips the persisted initial order through JSON' do
    tableau = described_class.new(columns: columns)
    restored = described_class.from_h(JSON.parse(JSON.generate(tableau.to_h)))
    expect(restored.snapshot).to eq(columns)
    restored.snapshot[0].shift
    expect(restored.front_ids).to eq(%w[SPA TUN NP])
  end

  it 'can snapshot a partially consumed display without making it a second source of truth' do
    tableau = described_class.new(columns: columns)
    tableau.take_front!('SPA')
    tableau.take_front!('TUN')
    restored = described_class.from_h(JSON.parse(JSON.generate(tableau.to_h)))
    expect(restored.snapshot).to eq(tableau.snapshot)
    expect(restored.front_ids).to eq(%w[ADA RES NP])
  end

  it 'uses a bounded Fisher-Yates shuffle supplied by setup' do
    limits = []
    tableau = described_class.shuffled(random_index: lambda do |limit|
      limits << limit
      0
    end)

    expect(limits).to eq((2..12).to_a.reverse)
    expect(tableau.snapshot.flatten).to contain_exactly(*described_class::COMPANY_IDS)
    expect(tableau.front_ids.size).to eq(3)
    expect { described_class.shuffled(random_index: ->(_limit) { -1 }) }
      .to raise_error(ArgumentError, /Random index/)
  end

  it 'rebuilds the same runtime display by replaying company choices' do
    initial = described_class.new(columns: columns)
    replayed = described_class.from_h(JSON.parse(JSON.generate(initial.to_h)))
    %w[TUN RES SPA].each do |company_id|
      initial.take_front!(company_id)
      replayed.take_front!(company_id)
    end
    expect(replayed.snapshot).to eq(initial.snapshot)
  end
end
