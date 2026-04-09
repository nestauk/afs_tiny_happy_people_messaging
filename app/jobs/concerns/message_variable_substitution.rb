module MessageVariableSubstitution
  extend ActiveSupport::Concern

  private

  def substitute_variables(content, user, token: nil)
    translations = {
      "{{parent_name}}": user.first_name || "",
      "{{child_name}}": user.child_name.presence || I18n.t(".messages.your_child", locale: user.language || I18n.default_locale),
      "{{link}}": token ? track_link_url(token) : nil,
    }

    result = content.gsub(/({{parent_name}}|{{child_name}}|{{link}})/) do |match|
      translations[match.to_sym]
    end

    result.gsub(/\s+([!?,.:])/, '\1').gsub(/\s{2,}/, " ").strip
  end
end
