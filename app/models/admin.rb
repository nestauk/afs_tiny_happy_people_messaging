class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :magic_link_authenticatable

  validates :email, presence: true, uniqueness: true

  attribute :role, admin: "admin", local_authority: "local_authority"
end
