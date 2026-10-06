class NameProfanityCheck
  WORDLIST_PATH = Rails.root.join("config/profanity_words.yml")

  def self.words
    @words ||= YAML.load_file(WORDLIST_PATH)
  end

  def initialize(name)
    @words_in_name = name.to_s.downcase.split(/\s+/).map { |word| word.gsub(/[^a-z]/, "") }.reject(&:empty?)
    @normalized = @words_in_name.join
  end

  def exact_match?
    @words_in_name.any? { |word| self.class.words.include?(word) }
  end

  def contains_match?
    self.class.words.any? { |word| @normalized.include?(word) }
  end
end
