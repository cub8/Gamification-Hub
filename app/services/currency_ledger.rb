# frozen_string_literal: true

class CurrencyLedger
  # The filter chips, in the order they are shown. `nil` is "Wszystkie".
  # Plural, unlike LedgerEntry::KIND_LABELS — a chip names a set of rows, a
  # chip on a row names one.
  KINDS = [
    [nil, 'Wszystkie'],
    %w[reward Nagrody],
    %w[purchase Zakupy],
    %w[adjustment Korekty],
  ].freeze

  def initialize(student:)
    @student = student
  end

  attr_reader :student

  # Newest first, each row carrying the balance it left behind.
  def entries(kind: nil)
    return all_entries if kind.blank?

    all_entries.select { |entry| entry.kind == kind }
  end

  def counts
    @counts ||= all_entries.group_by(&:kind).transform_values(&:size)
  end

  def count_for(kind)
    return size if kind.blank?

    counts.fetch(kind, 0)
  end

  def size    = all_entries.size
  def any?    = all_entries.any?
  def balance = student.current_currency.to_i
  def total   = student.total_currency.to_i

  private

  def all_entries
    @all_entries ||= begin
      running = balance

      transactions.map do |transaction|
        entry = build_entry(transaction, running)
        running -= transaction.amount.to_i
        entry
      end
    end
  end

  def transactions
    @transactions ||= student.currency_transactions
                             .includes(:granted_by_user, :transactionable)
                             .order(created_at: :desc, id: :desc)
                             .to_a
  end

  def build_entry(transaction, running)
    subject = transaction.transactionable

    LedgerEntry.new(transaction:   transaction,
                    title:         title_for(transaction, subject),
                    context:       context_for(transaction, subject),
                    balance_after: running,
                    withdrawn:     subject.is_a?(Item) && subject.deleted?,)
  end

  # A grading-sheet column has no name of its own — `didactic_description` is
  # what the teacher wrote in the header, and it is what the student was told
  # they were being awarded for.
  def title_for(transaction, subject)
    case subject
    when Item                  then subject.name
    when ActivityGroupCategory then subject.didactic_description.presence || 'Nagroda'
    else                            transaction.reward? ? 'Nagroda' : 'Korekta waluty'
    end
  end

  # The second, smaller line. It answers "where did this come from" — the
  # sheet for a reward, the teacher for a correction. A purchase needs none:
  # the item name above it is the whole answer.
  def context_for(transaction, subject)
    return sheet_names[subject.activity_group_id] if subject.is_a?(ActivityGroupCategory)
    return transaction.granted_by_user&.full_name if transaction.adjustment?

    nil
  end

  # One query for every sheet named in the whole ledger, rather than walking
  # category -> activity_group per row.
  def sheet_names
    @sheet_names ||= begin
      ids = transactions.filter_map do |transaction|
        subject = transaction.transactionable
        subject.activity_group_id if subject.is_a?(ActivityGroupCategory)
      end

      ActivityGroup.where(id: ids.uniq).pluck(:id, :name).to_h
    end
  end
end
