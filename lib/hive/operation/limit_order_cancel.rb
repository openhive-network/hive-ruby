class Hive::Operation::LimitOrderCancel < Hive::Operation
  def_attr owner: :string
  def_attr orderid: :uint32
end
