class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :magic_link_authenticatable

  validates :email, presence: true, uniqueness: true

  enum :role, {admin: "admin", super_admin: "super_admin"}
end
