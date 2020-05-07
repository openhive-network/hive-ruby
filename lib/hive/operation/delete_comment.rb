class Hive::Operation::DeleteComment < Hive::Operation
  def_attr author: :string
  def_attr permlink: :string
end
