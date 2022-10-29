module Hive
  class Operation
    include JSONable
    include Serializable
    include Utils
    
    # IDs derrived from:
    # https://gitlab.syncad.com/hive/hive/-/blob/master/libraries/protocol/include/hive/protocol/operations.hpp
    
    IDS = [
      :vote_operation,
      :comment_operation,

      :transfer_operation,
      :transfer_to_vesting_operation,
      :withdraw_vesting_operation,

      :limit_order_create_operation,
      :limit_order_cancel_operation,

      :feed_publish_operation,
      :convert_operation,

      :account_create_operation,
      :account_update_operation,

      :witness_update_operation,
      :account_witness_vote_operation,
      :account_witness_proxy_operation,

      :pow_operation,

      :custom_operation,

      :witness_block_approve_operation,

      :delete_comment_operation,
      :custom_json_operation,
      :comment_options_operation,
      :set_withdraw_vesting_route_operation,
      :limit_order_create2_operation,
      :claim_account_operation,
      :create_claimed_account_operation,
      :request_account_recovery_operation,
      :recover_account_operation,
      :change_recovery_account_operation,
      :escrow_transfer_operation,
      :escrow_dispute_operation,
      :escrow_release_operation,
      :pow2_operation,
      :escrow_approve_operation,
      :transfer_to_savings_operation,
      :transfer_from_savings_operation,
      :cancel_transfer_from_savings_operation,
      :custom_binary_operation,
      :decline_voting_rights_operation,
      :reset_account_operation,
      :set_reset_account_operation,
      :claim_reward_balance_operation,
      :delegate_vesting_shares_operation,
      :account_create_with_delegation_operation,
      :witness_set_properties_operation,
      :account_update2_operation,
      :create_proposal_operation,
      :update_proposal_votes_operation,
      :remove_proposal_operation,
      :update_proposal_operation,
      :collateralized_convert_operation,
      :recurrent_transfer_operation,
      
      # SMT operations
      :claim_reward_balance2_operation,

      :smt_setup_operation,
      :smt_setup_emissions_operation,
      :smt_set_setup_parameters_operation,
      :smt_set_runtime_parameters_operation,
      :smt_create_operation,
      :smt_contribute_operation,
    ] + VIRTUAL_OP_IDS = [
      # virtual operations below this point
      :fill_convert_request_operation,
      :author_reward_operation,
      :curation_reward_operation,
      :comment_reward_operation,
      :liquidity_reward_operation,
      :interest_operation,
      :fill_vesting_withdraw_operation,
      :fill_order_operation,
      :shutdown_witness_operation,
      :fill_transfer_from_savings_operation,
      :hardfork_operation,
      :comment_payout_update_operation,
      :return_vesting_delegation_operation,
      :comment_benefactor_reward_operation,
      :producer_reward_operation,
      :clear_null_account_balance_operation,
      :proposal_pay_operation,
      :dhf_funding_operation,
      :hardfork_hive_operation,
      :hardfork_hive_restore_operation,
      :delayed_voting_operation,
      :consolidate_treasury_balance_operation,
      :effective_comment_vote_operation,
      :ineffective_delete_comment_operation,
      :dhf_conversion_operation,
      :expired_account_notification_operation,
      :changed_recovery_account_operation,
      :transfer_to_vesting_completed_operation,
      :pow_reward_operation,
      :vesting_shares_split_operation,
      :account_created_operation,
      :fill_collateralized_convert_request_operation,
      :system_warning_operation,
      :fill_recurrent_transfer_operation,
      :failed_recurrent_transfer_operation,
      :limit_order_cancelled_operation,
      :producer_missed_operation,
      :proposal_fee_operation,
      :collateralized_convert_immediate_conversion_operation,
      :escrow_approved_operation,
      :escrow_rejected_operation
    ]
    
    def self.op_id(op)
      IDS.find_index op
    end

    def inspect
      properties = self.class.attributes.map do |prop|
        unless (v = instance_variable_get("@#{prop}")).nil?
          v = if v.respond_to? :strftime
            v.strftime('%Y-%m-%dT%H:%M:%S')
          else
            v
          end
          
          "@#{prop}=#{v}"
        end
      end.compact.join(', ')
      
      "#<#{self.class.name} [#{properties}]>"
    end
    
    def [](key)
      key = key.to_sym
      send(key) if self.class.attributes.include?(key)
    end

    def []=(key, value)
      key = key.to_sym
      
      if self.class.attributes.include?(key)
        if self.class.numeric? key
          send("#{key}=", value.to_i)
        else
          send("#{key}=", value)
        end
      end
    end
    
    def ==(other_op)
      return false if self.class != other_op.class
      
      self.class.attributes.each do |prop|
        return false if self[prop] != other_op[prop]
      end
      
      true
    end
  end
end
