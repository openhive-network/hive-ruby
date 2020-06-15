class Hive::Operation::CreateProposal < Hive::Operation
  def_attr creator: :string
  def_attr receiver: :string
  def_attr start_date: :point_in_time
  def_attr end_date: :point_in_time
  def_attr daily_pay: :amount
  def_attr subject: :string
  def_attr permlink: :string
end
