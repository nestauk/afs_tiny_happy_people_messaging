class AutoResponse < ApplicationRecord
  validates :trigger_phrase, :response, presence: true
end
