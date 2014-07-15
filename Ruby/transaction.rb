class Transaction < ActiveRecord::Base
  # Transaction specific code goes here
end

# This model is used to return an exportable format
# of the merchant's transactions by doing some
# joins with tables that store important information
# that always needs to be displayed with the transaction.
# An example usage is in transaction listing in MWI or
# the new dashboard or when exporting transactions
class ExportableTransaction < Transaction
  # A scope that returns the total amount for successful transactions
  # in a specific time interval
  scope :total_amount, ->(from_date, to_date) do
    where(
      server_time_created_at: from_date..to_date,
      tx_result: Transaction::TRANSACTION_SUCCESSFUL
    ).sum(:amount).to_f
  end

 # A scope to return the shortened form of the transactions.
  # Used in transaction listing page
  scope :shortened, -> do
    select(
      "transactions.id, transactions.transaction_code, transactions.product_summary,
      transactions.server_transaction_id, transactions.currency, transactions.amount,
      transactions.lat, transactions.lon, merchants.merchant_code,
      merchant_terminals.terminal_id
      "
    )
    .joins("left join merchants on transactions.merchant_id = merchants.id")
    .joins("left join merchant_terminals on merchant_terminals.merchant_id = merchants.id")
  end

  # Scope to return the details of transactions
  # that do SQL joins with tables saving
  # important information about the transaction such as
  # the card used in the transaction, transaction_status
  # and merchants tables. This is used in the export
  # feature
  scope :detailed, -> do
    # Building up the sql
    select(
      "transactions.*, tx_result as status, merchants.merchant_code, payment_types.description,
      transaction_statuses.name as status_name, card_id,
      '**** **** ****' || cards.last_4_digits AS card_number,
      transaction_states.created_at as paid_out_at, users.id as user_id"
    ).states.card_scheme
    .joins("left join cards on transactions.card_id = cards.id")
    .joins("left join merchants on transactions.merchant_id = merchants.id")
    .joins("left join payment_types on transactions.payment_type = payment_types.id")
    .joins("left join users on users.merchant_id = merchants.id")
    .joins(
      "left join transaction_states on transaction_states.transaction_id = transactions.id and
      transaction_states.transaction_status_id = transactions.current_status_id"
    )
    .order("transactions.server_time_created_at DESC")
  end
end

# Rspec tests
describe ExportableTransaction do
  let(:merchant) { create(:merchant, country: Country.de) }
  let(:transactions_count) { 5 }
  let(:paid_out_status) { TransactionStatus.where(name: TransactionStatus::PAID_OUT).first }
  let(:transactions) do
    transactions_count.times.map do
     create(
      :transaction,
      merchant: merchant,
      current_status_id: paid_out_status.id,
      tx_result: Transaction::TRANSACTION_SUCCESSFUL
    )
   end
  end

  let(:old_transaction) do
    create(
      :transaction,
      merchant: merchant,
      current_status_id: paid_out_status.id,
      tx_result: Transaction::TRANSACTION_SUCCESSFUL,
      server_time_created_at: 1.month.ago
    )
  end

  context "merchant's shortened transactions" do
    it "returns the merchant's transactions" do
      transactions

      expect(
        merchant.exportable_transactions.shortened.map(&:transaction_code).sort
      ).to eq(merchant.transactions.pluck(:transaction_code).sort)
    end
  end

  context "total amount per time" do
    it "returns the total amout in a specific time frame" do
      transactions
      old_transaction

      expect(
        merchant.exportable_transactions.total_amount(1.day.ago, Time.now)
      ).to eq(transactions.sum(&:amount).to_f)

      expect(
        merchant.exportable_transactions.total_amount(2.months.ago, 1.month.ago)
      ).to eq(old_transaction.amount.to_f.round(2))
    end
  end
end