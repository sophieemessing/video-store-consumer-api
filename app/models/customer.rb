class Customer < ApplicationRecord
  has_many :rentals
  has_many :videos, through: :rentals

  def videos_checked_out_count
    self.rentals.where(returned: false).length
  end
end
