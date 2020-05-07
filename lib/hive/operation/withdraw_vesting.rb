class Hive::Operation::WithdrawVesting < Hive::Operation
  def_attr account: :string
  def_attr vesting_shares: :amount
end
