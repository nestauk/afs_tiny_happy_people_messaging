module MessageVariableSubstitution
  extend ActiveSupport::Concern

  private

  def substitute_variables(content, user, token: nil)
    translations = {
      "{{parent_name}}": user.first_name,
      "{{child_name}}": user.child_name.presence || "your child",
      "{{link}}": token ? track_link_url(token) : nil,
    }

    content.gsub(/({{parent_name}}|{{child_name}}|{{link}})/) do |match|
      translations[match.to_sym]
    end
  end
end
