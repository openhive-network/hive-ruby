class Hive::Operation::TransferToVesting < Hive::Operation
  def_attr from: :string
  def_attr to: :string
  def_attr amount: :amount
end
