class Hive::Operation::ClaimRewardBalance < Hive::Operation
  def_attr account: :string
  def_attr reward_hive: :amount
  def_attr reward_hbd: :amount
  def_attr reward_vests: :amount
end
