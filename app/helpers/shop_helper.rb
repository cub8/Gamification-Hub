# frozen_string_literal: true

module ShopHelper
  def discount_label(discount)
    if discount.capped
      '(MAX -50%)'
    else
      "(-#{discount.value}%)"
    end
  end
end
