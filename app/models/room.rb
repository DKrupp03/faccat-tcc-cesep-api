class Room < ApplicationRecord
  has_many(:services, dependent: :nullify)

  normalizes(:name, with: ->(name) { name.strip })

  validates(:name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 })

  def show
    self.attributes.slice("id", "name")
  end
end
