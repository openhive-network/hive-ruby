class Hive::Operation::ProveAuthority < Hive::Operation
  def_attr challenged: :string
  def_attr require_owner: :boolean
end
