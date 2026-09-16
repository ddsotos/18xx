# frozen_string_literal: true

require './spec/spec_helper'

describe Engine::Game::GRotLA::FoundingAuctionState do
  let(:players) { %w[p1 p2 p3 p4] }
  let(:tableau) do
    Engine::Game::GRotLA::MinorTableau.new(
      columns: [%w[SPA ADA BRI OVN], %w[TUN RES EM AGR], %w[NP XPN XPR SUB]],
    )
  end

  it 'starts at 120 or a higher multiple of five and moves clockwise' do
    auction = described_class.new(player_ids: players, initiator_id: 'p2', price: 120)
    expect(auction.to_h).to include(
      'high_bidder_id' => 'p2',
      'high_bid' => 120,
      'current_bidder_id' => 'p3',
      'phase' => 'bidding',
      'resume_player_id' => 'p3',
    )
    expect { described_class.new(player_ids: players, initiator_id: 'p1', price: 119) }.to raise_error(ArgumentError)
    expect { described_class.new(player_ids: players, initiator_id: 'p1', price: 122) }.to raise_error(ArgumentError)
  end

  it 'requires increasing five-step bids and leaves state intact after rejection' do
    auction = described_class.new(player_ids: players, initiator_id: 'p1', price: 120)
    before = auction.to_h
    expect { auction.bid!('p2', 122) }.to raise_error(ArgumentError)
    expect(auction.to_h).to eq(before)
    auction.bid!('p2', 125)
    expect(auction.to_h).to include('high_bidder_id' => 'p2', 'high_bid' => 125, 'current_bidder_id' => 'p3')
  end

  it 'keeps auction withdrawal separate and never allows a bidder to rejoin' do
    auction = described_class.new(player_ids: players, initiator_id: 'p1', price: 120)
    auction.pass!('p2')
    auction.pass!('p3')
    auction.bid!('p4', 125)
    expect { auction.bid!('p2', 130) }.to raise_error(ArgumentError, /turn|rejoin/)
    auction.pass!('p1')
    expect(auction.phase).to eq(:company_choice)
    expect(auction.winner_id).to eq('p4')
  end

  it 'lets only the winner choose a currently available company' do
    auction = described_class.new(player_ids: players, initiator_id: 'p1', price: 120)
    auction.pass!('p2')
    auction.pass!('p3')
    auction.pass!('p4')
    before = tableau.snapshot
    expect { auction.choose_company!('p2', 'SPA', tableau: tableau) }.to raise_error(ArgumentError, /winner/)
    expect { auction.choose_company!('p1', 'ADA', tableau: tableau) }.to raise_error(ArgumentError, /not available/)
    expect(tableau.snapshot).to eq(before)

    expect(auction.choose_company!('p1', 'SPA', tableau: tableau)).to eq('SPA')
    expect(auction.phase).to eq(:complete)
    expect(auction.chosen_company_id).to eq('SPA')
    expect(tableau.front_ids).to eq(%w[ADA TUN NP])
  end

  it 'resumes after the initiator rather than after a different winner' do
    auction = described_class.new(player_ids: players, initiator_id: 'p2', price: 120)
    auction.bid!('p3', 125)
    auction.pass!('p4')
    auction.pass!('p1')
    auction.pass!('p2')
    expect(auction.winner_id).to eq('p3')
    expect(auction.resume_player_id).to eq('p3')
  end
end
