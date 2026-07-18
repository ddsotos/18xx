# frozen_string_literal: true

require_relative '../../../step/route'

module Engine
  module Game
    module G1890
      module Step
        class Route < Engine::Step::Route
          def process_run_routes(action)
            face, revenue = @game.hanshin_tigers_revenue(action.entity, action.routes)
            if revenue&.positive?
              @log << "#{action.entity.name} rolls #{face} for Hanshin Tigers popularity and receives "\
                      "#{@game.format_currency(revenue)}"
              action = Action::RunRoutes.new(
                action.entity,
                routes: action.routes,
                extra_revenue: action.extra_revenue + revenue,
              )
            end

            super(action)
          end
        end
      end
    end
  end
end
