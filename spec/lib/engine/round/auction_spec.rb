# frozen_string_literal: true

require './spec/spec_helper'

module Engine
  describe Round::Auction do
    context '#1828' do
      let(:players) { %w[a b c] }
      let(:game) { Game::G1828::Game.new(players) }
      let(:player_1) { game.player_by_id('a') }
      let(:player_2) { game.player_by_id('b') }
      let(:player_3) { game.player_by_id('c') }
      let(:svn) { game.companies[0] }
      let(:stct) { game.companies[1] }
      let(:cstl) { game.companies[2] }
      let(:mh) { game.companies[5] }
      let(:ca) { game.companies[7] }

      subject { Round::Auction.new(game, [Game::G1828::Step::WaterfallAuction]) }

      it 'shouldnt let SVN be purchased without a bid on StCT' do
        expect(subject.active_step.may_purchase?(svn)).to be false
      end

      it 'should let SVN be purchased with a bid on StCT' do
        subject.process_action(Action::Bid.new(player_1, company: stct, price: 25))
        expect(subject.active_step.may_purchase?(svn)).to be true
      end

      it 'should let CSTL be purchased after SVN and StCT are purchased' do
        subject.process_action(Action::Bid.new(player_1, company: stct, price: 25))
        subject.process_action(Action::Bid.new(player_2, company: svn, price: 20))
        expect(player_1.companies.count).to equal 1
        expect(player_1.companies.first).to be stct
        expect(player_2.companies.count).to equal 1
        expect(player_2.companies.first).to be svn
        expect(subject.active_step.may_purchase?(cstl)).to be true
      end

      it 'should pay the players private revenue if everyone passes' do
        subject.process_action(Action::Bid.new(player_1, company: stct, price: 25))
        subject.process_action(Action::Bid.new(player_2, company: svn, price: 20))

        p1_cash = player_1.cash
        p2_cash = player_2.cash

        subject.process_action(Action::Pass.new(player_3))
        subject.process_action(Action::Pass.new(player_1))
        subject.process_action(Action::Pass.new(player_2))
        expect(player_1.cash).to equal p1_cash + stct.revenue
        expect(player_2.cash).to equal p2_cash + svn.revenue
      end

      it 'should process all bids if everyone passes' do
        subject.process_action(Action::Bid.new(player_1, company: stct, price: 25))
        subject.process_action(Action::Bid.new(player_2, company: mh, price: 125))
        subject.process_action(Action::Bid.new(player_3, company: mh, price: 130))
        subject.process_action(Action::Bid.new(player_1, company: ca, price: 165))
        subject.process_action(Action::Bid.new(player_2, company: svn, price: 20))

        subject.process_action(Action::Pass.new(player_3))
        subject.process_action(Action::Pass.new(player_1))
        subject.process_action(Action::Pass.new(player_2))

        expect(subject.current_entity).to eq(player_2)
        subject.process_action(Action::Pass.new(player_2))

        expect(subject.current_entity).to eq(player_3)
        expect(player_1.companies.count).to equal 2
        expect(player_1.companies).to include(stct, ca)
        expect(player_2.companies.count).to equal 1
        expect(player_2.companies.first).to be svn
        expect(player_3.companies.count).to equal 1
        expect(player_3.companies.first).to be mh
        expect(subject.active_step.available.first).to be cstl
        expect(subject.active_step.may_purchase?(cstl)).to be true
      end
    end
  end
end
