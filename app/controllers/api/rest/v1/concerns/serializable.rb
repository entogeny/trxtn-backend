module Api
  module Rest
    module V1
      module Concerns
        module Serializable
          extend ActiveSupport::Concern

          DEFAULT_STATUS = :ok

          def render_serialized_json(serializer, data, options = {}, status: DEFAULT_STATUS)
            defaults = {
              root: :data,
              view: :standard
            }

            root = options[:root] || defaults[:root]
            view = options[:view] || defaults[:view]

            render json: serializer.render(data, {
              meta: options[:meta],
              root: root.to_sym,
              view: view&.to_sym
            }), status: status
          end

          def serialization_params
            default_params = {
              serialization: {
                view: :standard
              }
            }

            permitted_params = params.permit(
              serialization: [
                :view
              ]
            )

            permitted_params = default_params.merge(permitted_params).with_indifferent_access
            permitted_params[:serialization]
          end
        end
      end
    end
  end
end
