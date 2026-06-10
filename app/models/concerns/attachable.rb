module Attachable
  extend ActiveSupport::Concern

  private

  # Serializa os anexos (Active Storage) no formato consumido pelo front.
  def attachments_json
    attachments.map do |a|
      { id: a.id, name: a.blob.filename.to_s, url: rails_blob_url(a) }
    end
  end
end
