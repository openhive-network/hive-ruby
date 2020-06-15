class Hive::Operation::RemoveProposal < Hive::Operation
  def_attr proposal_owner: :string
  def_attr proposal_ids: :uint64_array
end
