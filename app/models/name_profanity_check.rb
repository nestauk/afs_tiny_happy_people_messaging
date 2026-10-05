class NameProfanityCheck
  WORDLIST_PATH = Rails.root.join("config/profanity_words.yml")

  def self.words
    @words ||= YAML.load_file(WORDLIST_PATH)
  end

  def initialize(name)
    @normalized = name.to_s.downcase.gsub(/[^a-z]/, "")
  end

  def exact_match?
    self.class.words.include?(@normalized)
  end

  def contains_match?
    self.class.words.any? { |word| @normalized.include?(word) }
  end
end
