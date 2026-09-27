# frozen_string_literal: true

class LedgerEntry
  KIND_LABELS = {
    'reward'     => 'Nagroda',
    'purchase'   => 'Zakup',
    'adjustment' => 'Korekta',
  }.freeze

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

  def withdrawn? = @withdrawn

  def signed_amount
    amount.negative? ? "−#{amount.abs}" : "+#{amount}"
  end
end
