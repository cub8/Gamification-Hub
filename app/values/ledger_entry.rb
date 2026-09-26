# frozen_string_literal: true

class LedgerEntry
  # The three labels the type chip can carry. Ported from the mockup's
  # TL = {earn:'Nagroda', spend:'Zakup', corr:'Korekta'} (30-sp.js:29), which
  # already matches CurrencyTransaction's own three kinds.
  KIND_LABELS = {
    'reward'     => 'Nagroda',
    'purchase'   => 'Zakup',
    'adjustment' => 'Korekta',
  }.freeze

  # The class suffix that colours the amount and the chip. Rewards are green
  # and purchases orange (--gh-earn / --gh-spend); a correction is neither,
  # because it can go either way and the sign already says which.
  KIND_TONES = {
    'reward'     => 'earn',
    'purchase'   => 'spend',
    'adjustment' => 'corr',
  }.freeze

  def initialize(transaction:, title:, context: nil, balance_after: 0, withdrawn: false)
    @transaction   = transaction
    @title         = title
    @context       = context
    @balance_after = balance_after
    @withdrawn     = withdrawn
  end

  attr_reader :transaction, :title, :context, :balance_after

  def id          = transaction.id
  def amount      = transaction.amount.to_i
  def kind        = transaction.kind.to_s
  def occurred_at = transaction.created_at

  def label = KIND_LABELS.fetch(kind, kind)
  def tone  = KIND_TONES.fetch(kind, 'corr')

  def reward?     = kind == 'reward'
  def purchase?   = kind == 'purchase'
  def correction? = kind == 'adjustment'

  # The item behind a purchase has since been taken off the shelf. The row
  # stays — soft delete keeps history intact (DECISIONS.md:28) — and says so.
  def withdrawn? = @withdrawn

  # "+12" / "−15", with U+2212 rather than a hyphen, as everywhere else in
  # this UI. Never "+0": a zero-value row would be a correction of nothing.
  def signed_amount
    amount.negative? ? "−#{amount.abs}" : "+#{amount}"
  end
end
