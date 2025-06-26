namespace :create_content_age_groups do
  desc "Create default content age groups"
  task create: :environment do
    ContentAgeGroup.find_or_create_by!(min_months: 3, max_months: 6) do |group|
      group.description = "🐨 Tiny Koala - Cuddles & Cooing
        Your baby is just beginning to coo, smile, or notice your voice. They love being close and respond with little movements or sounds.
        Best for babies who aren't yet sitting up or babbling much.
        Example content: Tummy time, cooing, face play, songs during routine "
      group.min_months = 3
      group.max_months = 6
    end

    ContentAgeGroup.find_or_create_by!(min_months: 7, max_months: 9) do |group|
      group.description = "🐝 Tiny Bumblebee - Babbles & Giggles
        Your little one is starting to make different sounds and movements. They may babble, reach for things, or even crawl toward their favorite toys. 
        Ideal for babies who are active and social but not yet using real words.
        Example content: Peekaboo, bubbles, object exploration, snack-time chat"
      group.min_months = 7
      group.max_months = 9
    end

    ContentAgeGroup.find_or_create_by!(min_months: 10, max_months: 12) do |group|
      group.description = "🐘 Tiny Elephant - First words, big feelings
        Your child might say a few single words like “mama” and understand simple instructions. They’re curious and love crawling, pointing, and copying your words.
        Ideal for babies that have started using their first words and gestures to express themselves.
        Example content: Turn-taking games, interactive stories, playing with toys (e.g., hide and seek) and dancing time"
      group.min_months = 10
      group.max_months = 12
    end

    ContentAgeGroup.find_or_create_by!(min_months: 13, max_months: 18) do |group|
      group.description = "🐧 Tiny Penguin - Waddling & exploring
        Your little one might be stringing two or more words together, following simple instructions or expressing themselves  (sometimes loudly!).
        Best for toddlers who may have started walking and are beginning to understand what you mean when you talk to them. 
        Example content: Outdoor activities, Clapping games, Singing and lots of play with random objects"
      group.min_months = 13
      group.max_months = 18
    end

    ContentAgeGroup.find_or_create_by!(min_months: 19, max_months: 27) do |group|
      group.description = "🐬 Tiny Dolphin - playing with imagination
        Your child is using short phrases or sentences, enjoying pretend play, and showing strong preferences. 
        Perfect for chatty toddlers who are exploring language with more confidence.
        Example content: Pretend play, hide and seek, cooking games, naming feelings and reading time."
      group.min_months = 19
      group.max_months = 27
    end
  end
end
