class Hive::Operation::DeclineVotingRights < Hive::Operation
  def_attr account: :string
  def_attr decline: :boolean
end
