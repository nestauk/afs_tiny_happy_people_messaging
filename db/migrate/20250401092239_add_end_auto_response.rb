class AddEndAutoResponse < ActiveRecord::Migration[8.0]
  def change
    AutoResponse.find_by(trigger_phrase: "end").update(response: "Hi there! Thank you so much for being part of the Tiny Happy People text messaging programme. Before we stop sending you texts, could you let us know why you've decided to stop/pause? You can just text back the number that matches your reason, or feel free to reply with your own thoughts. 1. My family and I don’t have time to engage with the texts right now. 2. The texts don’t feel relevant to my family’s needs. 3. I get too many texts and it feels overwhelming. 4. Other (please share your reason). Thanks again! We really appreciate your feedback.")
  end
end
