class Registration
  include ActiveModel::Model

  attr_accessor :user_params, :referrer_params
  attr_reader :user

  def submit
    @user = User.new(user_params)
    @user.terms_agreed_at = Time.zone.now if @user.terms_agreed == "1"
    return false unless @user.save

    @user.update_local_authority
    UserReferrer.create(referrer_params) if referrer_params.values.any?(&:present?)
    schedule_next_step
    true
  end

  def waitlisted?
    @user.child_birthday > 9.months.ago.to_date
  end

  private

  def schedule_next_step
    waitlisted? ? @user.put_on_waitlist : nil
  end
end
