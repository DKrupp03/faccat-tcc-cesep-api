class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include Rails.application.routes.url_helpers

  def self.by_name(name)
    return where("name LIKE ?", "%#{name}%") if name.present?
    return all
  end
end
