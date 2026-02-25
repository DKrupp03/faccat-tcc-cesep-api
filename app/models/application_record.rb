class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.by_name(name)
    return where("name LIKE ?", "%#{name}%") if name.present?
    return all
  end
end
