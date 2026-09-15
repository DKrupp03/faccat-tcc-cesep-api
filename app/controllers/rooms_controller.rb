class RoomsController < ApplicationController
  before_action(:authenticate_user!)
  # A listagem alimenta o select do formulário de atendimento (qualquer
  # terapeuta); manter o cadastro de salas é só do admin.
  before_action(:require_admin!, except: [ :index ])

  def index
    render_json_success({ rooms: Room.order(:name).map(&:show) })
  end

  # Recebe a lista completa da modal e a aplica de uma vez: salas ausentes são
  # excluídas, as com id são renomeadas e as sem id, criadas. Qualquer erro
  # desfaz tudo, para a modal nunca ficar meio salva.
  def sync
    rooms = rooms_params
    kept_ids = rooms.filter_map { |room| room[:id].presence }

    Room.transaction do
      Room.where.not(id: kept_ids).destroy_all

      rooms.each do |room|
        if room[:id].present?
          Room.find(room[:id]).update!(name: room[:name])
        else
          Room.create!(name: room[:name])
        end
      end
    end

    render_json_success({ rooms: Room.order(:name).map(&:show) })
  rescue ActiveRecord::RecordInvalid => e
    render_json_errors(e.record.errors)
  rescue ActiveRecord::RecordNotFound
    render_not_found(Room)
  end

  private

  def require_admin!
    render_not_allowed unless Current.profile&.admin?
  end

  def rooms_params
    params.permit(rooms: [ :id, :name ]).fetch(:rooms, []).map { |room| room.to_h.symbolize_keys }
  end
end
