class AutoResponse < ApplicationRecord
  validates :trigger_phrase, presence: true

  before_validation :validate_conditions, :validate_update_user

  private

  def validate_conditions
    validate_json(conditions)
    parsed = JSON.parse(conditions)
    return true if parsed.empty?

    check_fields(:conditions, parsed)
    true
  end

  def validate_update_user
    validate_json(update_user)
    parsed = JSON.parse(update_user)
    return true if parsed.empty?

    check_fields(:update_user, parsed)
    true
  end

  def check_fields(attribute, fields)
    fields.each do |field, _value|
      unless User.column_names.include?(field.to_s) || User.reflect_on_association(field)
        errors.add(attribute, "invalid field '#{field}' - not found in User model")
        next
      end
    end
  end

  def validate_json(field)
    JSON.parse(field)
  rescue JSON::ParserError
    errors.add(:"#{field}", "must be a valid JSON object")
  end
end
