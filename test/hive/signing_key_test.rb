require 'test_helper'

module Hive
  class SigningKeyTest < Hive::Test
    def setup
      @wif = '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
      @private_key_hex = '89adb43eca25e6145da5b50116dc0c31f128de839b24ea69099259dd2a5c0725'
    end

    def test_from_base58_decodes_private_key_without_bitcoin_key
      key = SigningKey.from_base58(@wif)

      assert_equal @private_key_hex, key.private_key_hex
      refute key.compressed
    end

    def test_from_base58_rejects_bad_checksum
      bad_wif = @wif.sub(/.$/, 'D')

      assert_raises Hive::ArgumentError do
        SigningKey.from_base58(bad_wif)
      end
    end
  end
end
