module Sortable
  extend ActiveSupport::Concern

  included do
    class_attribute :sort_options, default: {}
    class_attribute :default_sort_option, default: {}
  end

  class_methods do
    # Declara o mapa de ordenação do controller.
    # Ex.: sortable("name_asc" => { name: :asc },
    #               "name_desc" => { name: :desc },
    #               default: { name: :asc })
    def sortable(map)
      options = map.dup
      self.default_sort_option = options.delete(:default) || {}
      self.sort_options = options
    end
  end

  private

  # Traduz params[:order_by] em cláusula de ordenação; cai no default quando ausente/desconhecido.
  def order_by
    sort_options.fetch(params[:order_by], default_sort_option)
  end
end
