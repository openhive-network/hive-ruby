# encoding: UTF-8
require 'json' unless defined?(JSON)
require 'net/https'

require 'hashie'
require 'hive/version'
require 'hive/utils'
require 'hive/base_error'
require 'hive/mixins/serializable'
require 'hive/mixins/jsonable'
require 'hive/mixins/retriable'
require 'hive/chain_config'
require 'hive/type/base_type'
require 'hive/type/amount'
require 'hive/operation'
require 'hive/operation/account_create.rb'
require 'hive/operation/account_create_with_delegation.rb'
require 'hive/operation/account_update.rb'
require 'hive/operation/account_witness_proxy.rb'
require 'hive/operation/account_witness_vote.rb'
require 'hive/operation/cancel_transfer_from_savings.rb'
require 'hive/operation/challenge_authority.rb'
require 'hive/operation/change_recovery_account.rb'
require 'hive/operation/claim_account.rb'
require 'hive/operation/claim_reward_balance.rb'
require 'hive/operation/comment.rb'
require 'hive/operation/comment_options.rb'
require 'hive/operation/convert.rb'
require 'hive/operation/create_claimed_account.rb'
require 'hive/operation/custom.rb'
require 'hive/operation/custom_binary.rb'
require 'hive/operation/custom_json.rb'
require 'hive/operation/decline_voting_rights.rb'
require 'hive/operation/delegate_vesting_shares.rb'
require 'hive/operation/delete_comment.rb'
require 'hive/operation/escrow_approve.rb'
require 'hive/operation/escrow_dispute.rb'
require 'hive/operation/escrow_release.rb'
require 'hive/operation/escrow_transfer.rb'
require 'hive/operation/feed_publish.rb'
require 'hive/operation/limit_order_cancel.rb'
require 'hive/operation/limit_order_create.rb'
require 'hive/operation/limit_order_create2.rb'
require 'hive/operation/prove_authority.rb'
require 'hive/operation/recover_account.rb'
require 'hive/operation/report_over_production.rb'
require 'hive/operation/request_account_recovery.rb'
require 'hive/operation/reset_account.rb'
require 'hive/operation/set_reset_account.rb'
require 'hive/operation/set_withdraw_vesting_route.rb'
require 'hive/operation/transfer.rb'
require 'hive/operation/transfer_from_savings.rb'
require 'hive/operation/transfer_to_savings.rb'
require 'hive/operation/transfer_to_vesting.rb'
require 'hive/operation/vote.rb'
require 'hive/operation/withdraw_vesting.rb'
require 'hive/operation/witness_update.rb'
require 'hive/operation/witness_set_properties.rb'
require 'hive/marshal'
require 'hive/transaction'
require 'hive/transaction_builder'
require 'hive/rpc/base_client'
require 'hive/rpc/http_client'
require 'hive/rpc/thread_safe_http_client'
require 'hive/api'
require 'hive/jsonrpc'
require 'hive/block_api'
require 'hive/formatter'
require 'hive/broadcast'
require 'hive/stream'
require 'hive/fallback'
require 'hive/bridge'

module Hive
  def self.api_classes
    @api_classes ||= {}
  end
  
  def self.const_missing(const)
    super unless const.to_s.end_with? 'Api'
    
    api = api_classes[const]
    api ||= Api.clone(freeze: true) rescue Api.clone
    api.api_name = const
    api_classes[const] = api
  end
end

Hashie.logger = Logger.new(ENV['HASHIE_LOGGER'])
