class Hive::Operation::FeedPublish < Hive::Operation
  def_attr publisher: :string
  def_attr exchange_rate: :price
end
