class Hive::Operation::ChallengeAuthority < Hive::Operation
  def_attr challenger: :string
  def_attr challenged: :string
  def_attr require_owner: :boolean
end
