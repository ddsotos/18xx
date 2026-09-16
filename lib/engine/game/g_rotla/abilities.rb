# frozen_string_literal: true

require_relative 'entities'

module Engine
  module Game
    module GRotLA
      # Ability ownership is game state rather than a corporation-name check.
      # The registry is rebuilt by replay: every Minor starts with one record,
      # and the merger action moves those records to the selected Major.
      module Abilities
        ABILITY_NAMES = {
          adaptive: 'Adaptive',
          agricultural: 'Agricultural',
          bridging: 'Bridging',
          eastern_mining: 'Eastern Mining',
          expansive: 'Expansive',
          express: 'Express',
          northern_port: 'Northern Port',
          overnight: 'Overnight',
          resourceful: 'Resourceful',
          spacious: 'Spacious',
          suburban: 'Suburban',
          tunneling: 'Tunneling',
        }.freeze
        IMPLEMENTED_ABILITIES = %i[adaptive express overnight spacious].freeze

        def rotla_ability_records(entity)
          return [] unless entity

          rotla_ability_registry.fetch(entity.id, [])
        end

        def rotla_ability_ids(entity)
          rotla_ability_records(entity).map { |record| record[:id] }
        end

        def rotla_has_ability?(entity, ability_id)
          rotla_ability_ids(entity).include?(ability_id.to_sym)
        end

        def rotla_ability_state(entity, ability_id)
          record = rotla_ability_records(entity).find { |candidate| candidate[:id] == ability_id.to_sym }
          record&.fetch(:state)
        end

        def rotla_transfer_abilities!(sources, target)
          records = Array(sources).flat_map { |source| rotla_ability_records(source) }
          combined = (rotla_ability_records(target) + records).uniq { |record| [record[:id], record[:source]] }
          rotla_ability_registry[target.id] = combined
          Array(sources).each { |source| rotla_ability_registry[source.id] = [] }
        end

        def rotla_ability_name(ability_id)
          ABILITY_NAMES.fetch(ability_id.to_sym, ability_id.to_s)
        end

        def rotla_ability_implemented?(ability_id)
          IMPLEMENTED_ABILITIES.include?(ability_id.to_sym)
        end

        private

        def rotla_ability_registry
          @rotla_ability_registry ||= Entities::ABILITY_BY_MINOR.to_h do |corporation_id, ability_id|
            record = { id: ability_id, source: corporation_id, state: {} }
            [corporation_id, [record]]
          end
        end
      end
    end
  end
end
