class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_create do
    # TODO: First: Implement create wallet.
    #
    # like this: wallet_id = Glueby::Wallet.create.id
  end
end
