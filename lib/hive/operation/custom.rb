class Hive::Operation::Custom < Hive::Operation
  def_attr required_auths: :required_auths
  def_attr id: :uint32
  def_attr data: :raw_bytes
end
