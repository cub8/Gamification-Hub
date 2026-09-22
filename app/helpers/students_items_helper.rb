# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in RedesignHelper.
module StudentsItemsHelper
  # "3 przedmioty. Wykorzystanie przedmiotu zgłaszasz prowadzącemu na zajęciach."
  def inventory_lead(count)
    "#{count} #{gh_plural(count, 'przedmiot', 'przedmioty', 'przedmiotów')}. " \
      'Wykorzystanie przedmiotu zgłaszasz prowadzącemu na zajęciach.'
  end

  # The student's own card foot: "Kupione 12.06, 10:21, za 15".
  def purchase_line(purchase)
    "Kupione #{gh_when(purchase.created_at)}, za #{purchase.price_paid}"
  end

  # The teacher's, on the sheet's Przedmioty tab. The price paid is in the cost
  # chip there, so this names the discount instead — what the item costs anyone
  # else is the part the teacher cannot see from the number alone.
  def purchase_teacher_line(purchase)
    line = "Kupione #{gh_when(purchase.created_at)}"
    list = purchase.item&.price.to_i

    return line if purchase.price_paid.to_i >= list

    "#{line}, ze zniżką z #{list}"
  end

  # "Stać cię teraz na 3 przedmioty w sklepie." — the dashed slot that closes
  # the grid, which is the whole reason this screen links to the shop at all.
  def inventory_shop_line(count)
    "Stać cię teraz na #{count} #{gh_plural(count, 'przedmiot', 'przedmioty', 'przedmiotów')} w sklepie."
  end
end
