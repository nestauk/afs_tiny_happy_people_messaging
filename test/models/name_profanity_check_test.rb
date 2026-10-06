require "test_helper"

class NameProfanityCheckTest < ActiveSupport::TestCase
  test "#exact_match? is true when the whole name matches a blocked word" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("damn").exact_match?
  end

  test "#exact_match? ignores case and punctuation" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("D.a.M.n").exact_match?
  end

  test "#exact_match? is false when the name only contains a blocked word" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert_not NameProfanityCheck.new("Damnata").exact_match?
  end

  test "#exact_match? is false for a clean name" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert_not NameProfanityCheck.new("Maya").exact_match?
  end

  test "#exact_match? is true when one word of a multi-word name exactly matches a blocked word" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("Little damn").exact_match?
  end

  test "#exact_match? ignores punctuation within a word of a multi-word name" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("Little D.a.M.n").exact_match?
  end

  test "#contains_match? is true when a blocked word appears anywhere in the name" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("Damnata").contains_match?
  end

  test "#contains_match? is true when a blocked word is split across words" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("Da mn").contains_match?
  end

  test "#exact_match? is false when a blocked word is split across words" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert_not NameProfanityCheck.new("Da mn").exact_match?
  end

  test "#contains_match? is true for an exact match too" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert NameProfanityCheck.new("damn").contains_match?
  end

  test "#contains_match? is false for a clean name" do
    NameProfanityCheck.stubs(:words).returns(["damn"])

    assert_not NameProfanityCheck.new("Maya").contains_match?
  end
end
