require 'test_helper'

module Hive
  class CompactSignerTest < Hive::Test
    def setup
      @private_key_hex = '89adb43eca25e6145da5b50116dc0c31f128de839b24ea69099259dd2a5c0725'
      @digest = "\x00" * 32
      @public_key_hex = '04604738fa008878e9e3a4853307ad41524234dd9e3d48ff559d4b04094c42800f493e3ef7be2d44601c8d073d035541196845d256518bf2d4aae7859038c7639e'
    end

    def test_rbsecp256k1_signs_compact_recoverable_signature
      signer = CompactSigner::Rbsecp256k1.new
      signature = signer.sign_compact(@digest, @private_key_hex, @public_key_hex, false)

      assert_equal 65, signature.bytesize
      assert_includes 27..30, signature.bytes.first
      assert_low_s signature
      assert_equal @public_key_hex, signer.recover_compact(@digest, signature)
    end

    def test_rbsecp256k1_signs_legacy_noncanonical_shape_as_lower_s_signature
      signer = CompactSigner::Rbsecp256k1.new
      transaction_hex = '62df7b81fb720ae4fb690201000f706172656e745f7065726d6c696e6b06736f6369616c087065726d6c696e6b057469746c6504626f6479197b22617070223a22686976652d727562792f312e302e36227d1306736f6369616c087065726d6c696e6b00ca9a3b00000000035342440000000010270101000000'
      digest = Digest::SHA256.digest([Hive::ChainConfig::NETWORKS_HIVE_CHAIN_ID + transaction_hex[0..-4]].pack('H*'))
      signature = signer.sign_compact(digest, @private_key_hex, @public_key_hex, false)

      assert_low_s signature
      refute legacy_canonical_signature_shape?(signature)
    end

    def test_rbsecp256k1_derives_public_key
      signer = CompactSigner::Rbsecp256k1.new

      assert_equal @public_key_hex, signer.public_key(@private_key_hex)
      assert_equal '02604738fa008878e9e3a4853307ad41524234dd9e3d48ff559d4b04094c42800f', signer.public_key(@private_key_hex, true)
    end

  private
    SECP256K1_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

    def assert_low_s(signature)
      s = signature.byteslice(33, 32).unpack1('H*').to_i(16)

      assert_operator s, :<=, SECP256K1_ORDER / 2
    end

    def legacy_canonical_signature_shape?(signature)
      sig = signature.unpack('C*')

      !(
        ((sig[0] & 0x80) != 0) || (sig[0] == 0) ||
        ((sig[1] & 0x80) != 0) ||
        ((sig[32] & 0x80) != 0) || (sig[32] == 0) ||
        ((sig[33] & 0x80) != 0)
      )
    end
  end
end
