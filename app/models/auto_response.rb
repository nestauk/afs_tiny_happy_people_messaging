class AutoResponse < ApplicationRecord
  validates :trigger_phrase, presence: true

  before_validation :validate_condition_and_update_fields

  private

  def validate_condition_and_update_fields
    %i[update_user user_conditions].each { |attr| validate_and_check_fields(attr, User) }
  end

  def validate_and_check_fields(attribute, model)
    parsed = parse_json(attribute)
    return if parsed.empty? || errors.any?

    check_fields(attribute, parsed, model)
    true
  end

  def parse_json(field)
    JSON.parse(send(field))
  rescue JSON::ParserError
    errors.add(field, "must be a valid JSON object")
    []
  end

  def check_fields(attribute, fields, model)
    fields.each do |field, _value|
      unless model.column_names.include?(field.to_s) || model.reflect_on_association(field)
        errors.add(attribute, "invalid field '#{field}' - not found in #{model.name} model")
      end
    end
  end
end
