# frozen_string_literal: true

require_relative 'entities'

module Engine
  module Game
    module GRotLA
      # Replayable three-column charter display. Index zero is the available
      # company in each column; the UI may render that entry at the bottom.
      class MinorTableau
        COLUMN_COUNT = 3
        COLUMN_SIZE = 4
        COMPANY_IDS = Entities::MINOR_COMPANIES.map { |company| company[:sym] }.freeze

        attr_reader :columns

        def self.shuffled(random_index:)
          ids = COMPANY_IDS.dup
          (ids.size - 1).downto(1) do |last|
            index = random_index.call(last + 1)
            valid_index = index.is_a?(Integer) && index.between?(0, last)
            raise ArgumentError, "Random index must be between 0 and #{last}" unless valid_index

            ids[last], ids[index] = ids[index], ids[last]
          end
          new(columns: ids.each_slice(COLUMN_SIZE).to_a)
        end

        def self.from_h(data)
          valid_snapshot = data.is_a?(Hash) && data.keys == ['columns']
          raise ArgumentError, 'Minor tableau snapshot requires exactly columns' unless valid_snapshot

          new(columns: data['columns'], require_complete: false)
        end

        def initialize(columns:, require_complete: true)
          @columns = copy_columns(columns)
          validate!(require_complete: require_complete)
        end

        def front_ids
          @columns.filter_map(&:first)
        end

        def front?(company_id)
          front_ids.include?(company_id)
        end

        def take_front!(company_id)
          column = @columns.find { |candidate| candidate.first == company_id }
          raise ArgumentError, "#{company_id} is not an available Minor Company" unless column

          column.shift
        end

        def empty?
          @columns.all?(&:empty?)
        end

        def snapshot
          copy_columns(@columns)
        end

        def to_h
          { 'columns' => snapshot }
        end

        private

        def copy_columns(columns)
          raise ArgumentError, 'Minor tableau columns must be an array' unless columns.is_a?(Array)

          columns.map do |column|
            raise ArgumentError, 'Each Minor tableau column must be an array' unless column.is_a?(Array)

            column.map { |company_id| company_id.is_a?(String) ? company_id.dup : company_id }
          end
        end

        def validate!(require_complete:)
          valid_shape = @columns.size == COLUMN_COUNT && @columns.all? { |column| column.size <= COLUMN_SIZE }
          raise ArgumentError, 'Minor tableau requires three columns of at most four companies' unless valid_shape

          ids = @columns.flatten
          known_unique_ids = ids == ids.grep(String) && ids.uniq.size == ids.size && (ids - COMPANY_IDS).empty?
          complete = !require_complete || ids.sort == COMPANY_IDS.sort
          valid_ids = known_unique_ids && complete
          return if valid_ids

          raise ArgumentError, 'Minor tableau must contain every Long Game Minor Company exactly once'
        end
      end
    end
  end
end
