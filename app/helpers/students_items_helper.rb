# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in ApplicationHelper.
module StudentsItemsHelper
  # "3 przedmioty. Wykorzystanie przedmiotu zgłaszasz prowadzącemu na zajęciach."
  def inventory_lead(count)
    t('students_items.helpers.inventory_lead', count: count)
  end

  # The student's own card foot: "Kupione 12.06, 10:21, za 15".
  def purchase_line(purchase)
    t('students_items.helpers.purchase_line', when: gh_when(purchase.created_at), price: purchase.price_paid)
  end

  # The teacher's, on the sheet's Przedmioty tab. The price paid is in the cost
  # chip there, so this names the discount instead — what the item costs anyone
  # else is the part the teacher cannot see from the number alone.
  def purchase_teacher_line(purchase)
    bought_at = gh_when(purchase.created_at)
    list      = purchase.item&.price.to_i

    return t('students_items.helpers.purchase_teacher_line', when: bought_at) if purchase.price_paid.to_i >= list

    t('students_items.helpers.purchase_teacher_discount', when: bought_at, list: list)
  end

  # "Stać cię teraz na 3 przedmioty w sklepie." — the dashed slot that closes
  # the grid, which is the whole reason this screen links to the shop at all.
  def inventory_shop_line(count)
    t('students_items.helpers.shop_line', count: count)
  end
end
