class Hive::Operation::UpdateProposalVotes < Hive::Operation
  def_attr voter: :string
  def_attr proposal_ids: :uint64_array
  def_attr approve: :boolean
end
