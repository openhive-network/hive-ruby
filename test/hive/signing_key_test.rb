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

    def test_from_base58_decodes_compressed_private_key
      key = SigningKey.from_base58('L1qLfs5M5yBoRjAR25Sx4GxmnrAvGua5mS22LBrJFsL6zknQrNjs')

      assert_equal @private_key_hex, key.private_key_hex
      assert key.compressed
    end

    def test_from_base58_preserves_leading_zero_bytes
      key = SigningKey.from_base58('5HpHagT65TZzG1PH3CSu63k8DbpvD8s5ip4nEB3kEsreAnchuDf')

      assert_equal '00' * 31 + '01', key.private_key_hex
      refute key.compressed
    end

    def test_from_base58_rejects_invalid_encoding_and_length
      [nil, 123, '', @wif[0...-1], @wif + '1', @wif + '11', '1' * 51, '0' + @wif[1..-1]].each do |wif|
        assert_raises(Hive::ArgumentError) { SigningKey.from_base58(wif) }
      end
    end

    def test_from_base58_rejects_wrong_version_and_compression_flag
      # These malformed payloads have valid checksums.
      {
        '5Lofa5rg2cbRZTKcvjLDt5YYxM2GCraiSoN76MfNvKbd61q7ycK' => 'Invalid private key version',
        'L1qLfs5M5yBoRjAR25Sx4GxmnrAvGua5mS22LBrJFsL6zkuMmNg1' => 'Invalid compressed private key flag'
      }.each do |wif, message|
        error = assert_raises(Hive::ArgumentError) { SigningKey.from_base58(wif) }

        assert_includes error.message, message
      end
    end
  end
end
