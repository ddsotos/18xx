# frozen_string_literal: true

module Engine
  module Game
    module GRotLA
      # State for auctioning the right to choose an available Minor Company.
      # Cash, share transfers, par price, and Adaptive home selection remain
      # responsibilities of the future stock-round Step.
      class FoundingAuctionState
        MIN_BID = 120
        BID_INCREMENT = 5

        attr_reader :initiator_id, :player_ids, :active_bidder_ids, :high_bidder_id,
                    :high_bid, :current_bidder_id, :phase, :chosen_company_id

        def initialize(player_ids:, initiator_id:, price:)
          @player_ids = validate_players(player_ids)
          raise ArgumentError, 'Auction initiator must be a player' unless @player_ids.include?(initiator_id)

          validate_price!(price, minimum: MIN_BID)
          @initiator_id = initiator_id.dup
          @active_bidder_ids = @player_ids.dup
          @high_bidder_id = @initiator_id
          @high_bid = price
          @current_bidder_id = next_active_after(@initiator_id)
          @phase = :bidding
          @chosen_company_id = nil
        end

        def bid!(player_id, price)
          validate_bidding_actor!(player_id)
          validate_price!(price, minimum: @high_bid + BID_INCREMENT)
          @high_bidder_id = player_id
          @high_bid = price
          @current_bidder_id = next_active_after(player_id)
        end

        def pass!(player_id)
          validate_bidding_actor!(player_id)
          @active_bidder_ids.delete(player_id)
          if @active_bidder_ids.one?
            @phase = :company_choice
            @current_bidder_id = @high_bidder_id
          else
            @current_bidder_id = next_active_after(player_id)
          end
        end

        def winner_id
          @phase == :company_choice || @phase == :complete ? @high_bidder_id : nil
        end

        def resume_player_id
          @player_ids[(@player_ids.index(@initiator_id) + 1) % @player_ids.size]
        end

        def choose_company!(player_id, company_id, tableau:)
          raise ArgumentError, 'Auction is not waiting for a company choice' unless @phase == :company_choice
          raise ArgumentError, 'Only the auction winner may choose a company' unless player_id == winner_id
          raise ArgumentError, 'Chosen company is not available' unless tableau.front?(company_id)

          tableau.take_front!(company_id)
          @chosen_company_id = company_id.dup
          @phase = :complete
          @current_bidder_id = nil
          company_id
        end

        def to_h
          {
            'initiator_id' => @initiator_id,
            'player_ids' => @player_ids.dup,
            'active_bidder_ids' => @active_bidder_ids.dup,
            'high_bidder_id' => @high_bidder_id,
            'high_bid' => @high_bid,
            'current_bidder_id' => @current_bidder_id,
            'phase' => @phase.to_s,
            'chosen_company_id' => @chosen_company_id,
            'resume_player_id' => resume_player_id,
          }
        end

        private

        def validate_players(player_ids)
          valid_players = player_ids.is_a?(Array) && player_ids.size > 1 &&
                          player_ids.all? { |id| id.is_a?(String) && !id.empty? } &&
                          player_ids.uniq.size == player_ids.size
          raise ArgumentError, 'Auction requires unique nonempty player IDs' unless valid_players

          player_ids.map(&:dup)
        end

        def validate_price!(price, minimum:)
          return if price.is_a?(Integer) && price >= minimum && (price % BID_INCREMENT).zero?

          raise ArgumentError, "Bid must be at least #{minimum} and a multiple of #{BID_INCREMENT}"
        end

        def validate_bidding_actor!(player_id)
          raise ArgumentError, 'Auction is not accepting bids' unless @phase == :bidding
          raise ArgumentError, 'It is not this player’s turn to bid' unless player_id == @current_bidder_id
          raise ArgumentError, 'A passed bidder cannot rejoin the auction' unless @active_bidder_ids.include?(player_id)
        end

        def next_active_after(player_id)
          start = @player_ids.index(player_id)
          1.upto(@player_ids.size) do |offset|
            candidate = @player_ids[(start + offset) % @player_ids.size]
            return candidate if @active_bidder_ids.include?(candidate)
          end
          nil
        end
      end
    end
  end
end
