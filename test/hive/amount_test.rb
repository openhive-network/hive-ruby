require 'test_helper'

module Hive
  class AmountTest < Hive::Test
    def setup
      @amount = Hive::Type::Amount.new('0.000 HIVE')
    end
    
    def test_to_s
      assert_equal '0.000 HBD', Hive::Type::Amount.to_s(['0', 3, '@@000000013'])
      assert_equal '0.000 HIVE', Hive::Type::Amount.to_s(['0', 3, '@@000000021'])
      assert_equal '0.000000 VESTS', Hive::Type::Amount.to_s(['0', 6, '@@000000037'])
      
      assert_raises TypeError do
        Hive::Type::Amount.to_s(['0', 3, '@@00000000'])
      end
    end
    
    def test_to_h
      assert_equal({amount: '0', precision: 3, nai: '@@000000013'}, Hive::Type::Amount.to_h('0.000 HBD'))
      assert_equal({amount: '0', precision: 3, nai: '@@000000021'}, Hive::Type::Amount.to_h('0.000 HIVE'))
      assert_equal({amount: '0', precision: 6, nai: '@@000000037'}, Hive::Type::Amount.to_h('0.000000 VESTS'))
      
      assert_raises TypeError do
        Hive::Type::Amount.to_h('0.000 BOGUS')
      end
    end
    
    def test_to_bytes
      assert @amount.to_bytes
    end
  end
end
