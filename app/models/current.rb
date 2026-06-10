class Current < ActiveSupport::CurrentAttributes
  attribute :user

  delegate :profile, :profile_id, to: :user, allow_nil: true
end
