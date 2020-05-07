class Hive::Operation::CancelTransferFromSavings < Hive::Operation
  def_attr from: :string
  def_attr request_id: :uint32
end
