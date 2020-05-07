class Hive::Operation::DelegateVestingShares < Hive::Operation
  def_attr delegator: :string
  def_attr delegatee: :string
  def_attr vesting_shares: :amount
end
