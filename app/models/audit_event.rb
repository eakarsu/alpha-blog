class AuditEvent < ActiveRecord::Base
  belongs_to :actor, class_name: "User", optional: true

  def self.record!(actor:, action:, subject:, metadata: {}, request_id: nil)
    create!(actor: actor, action: action, subject_type: subject.class.name,
            subject_id: subject.id, metadata: metadata, request_id: request_id)
  end
end
