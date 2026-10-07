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

    def test_rbsecp256k1_reports_missing_optional_dependency
      unavailable_signer = Class.new(CompactSigner::Rbsecp256k1) do
        def require(_path)
          raise LoadError, 'cannot load such file -- rbsecp256k1'
        end
      end

      error = assert_raises(LoadError) { unavailable_signer.new }

      assert_includes error.message, 'cannot load such file -- rbsecp256k1'
    end

    def test_default_prefers_native_and_only_falls_back_for_unavailability
      previous = CompactSigner.instance_variable_get(:@default)
      CompactSigner.instance_variable_set(:@default, nil)
      assert_instance_of CompactSigner::Rbsecp256k1, CompactSigner.default

      CompactSigner.instance_variable_set(:@default, nil)
      CompactSigner::Rbsecp256k1.stub(:new, -> { raise LoadError, 'extension unavailable' }) do
        assert_instance_of CompactSigner::PureRuby, CompactSigner.default
        assert_same CompactSigner.default, CompactSigner.default
      end

      CompactSigner.instance_variable_set(:@default, nil)
      Secp256k1.stub(:have_recovery?, false) do
        assert_instance_of CompactSigner::PureRuby, CompactSigner.default
      end

      CompactSigner.instance_variable_set(:@default, nil)
      CompactSigner::Rbsecp256k1.stub(:new, -> { raise Hive::BaseError, 'unexpected context failure' }) do
        assert_raises(Hive::BaseError) { CompactSigner.default }
      end
    ensure
      CompactSigner.instance_variable_set(:@default, previous)
    end

    def test_backends_recover_each_others_signatures_and_derive_identical_keys
      native = CompactSigner::Rbsecp256k1.new
      pure = CompactSigner::PureRuby.new
      keys = [@private_key_hex, '%064x' % 1, '%064x' % (SECP256K1_ORDER - 1)]
      digests = [@digest, "\xff".b * 32, Digest::SHA256.digest('Hive fallback')]

      keys.zip(digests).each do |key, digest|
        [false, true].each do |compressed|
          public_key = native.public_key(key, compressed)
          assert_equal public_key, pure.public_key(key, compressed)
          [[native, pure], [pure, native]].each do |signer, verifier|
            signature = signer.sign_compact(digest, key, public_key, compressed)
            assert_equal 65, signature.bytesize
            assert_includes(compressed ? 31..34 : 27..30, signature.getbyte(0))
            assert_low_s signature
            assert_equal public_key, verifier.recover_compact(digest, signature)
          end
        end
      end
    end

    def test_pure_signer_known_nonce_vector_and_entropy_failure
      signer = CompactSigner::PureRuby.new
      x = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'
      SecureRandom.stub(:random_number, ->(limit) { assert_equal SECP256K1_ORDER - 1, limit; 0 }) do
        signature = signer.sign_compact(@digest, '%064x' % 1)
        assert_equal '1b' + x + x, signature.unpack1('H*')
        # Same nonce and a different test digest exercises the low-S parity flip.
        digest = ['%064x' % (1 << 255)].pack('H*')
        signature = signer.sign_compact(digest, '%064x' % 1)
        assert_equal 28, signature.getbyte(0)
        assert_low_s signature
        assert_equal signer.public_key('%064x' % 1), CompactSigner::Rbsecp256k1.new.recover_compact(digest, signature)
      end
      SecureRandom.stub(:random_number, ->(*) { raise NotImplementedError, 'entropy unavailable' }) do
        assert_raises(NotImplementedError) { signer.sign_compact(@digest, @private_key_hex) }
      end
    end

    def test_pure_recovery_handles_overflow_recovery_ids
      native = CompactSigner::Rbsecp256k1.new
      pure = CompactSigner::PureRuby.new
      [29, 30, 33, 34].each do |header|
        signature = [header].pack('C') + ['%064x%064x' % [2, 1]].pack('H*')
        assert_equal native.recover_compact(@digest, signature), pure.recover_compact(@digest, signature)
      end
    end

    def test_both_backends_reject_invalid_inputs_and_wrong_public_keys
      [CompactSigner::Rbsecp256k1.new, CompactSigner::PureRuby.new].each do |signer|
        [nil, '', 'g' * 64, '0' * 64, '1' * 63, '%064x' % SECP256K1_ORDER].each do |key|
          assert_raises(Hive::ArgumentError) { signer.public_key(key) }
          assert_raises(Hive::ArgumentError) { signer.sign_compact(@digest, key) }
        end
        [nil, '', 'x' * 31, 'x' * 33, 'é' * 32].each do |digest|
          assert_raises(Hive::ArgumentError) { signer.sign_compact(digest, @private_key_hex) }
          assert_raises(Hive::ArgumentError) { signer.recover_compact(digest, 'x' * 65) }
        end
        [nil, '', 'x' * 64, "\x1a" + 'x' * 64, "\x23" + 'x' * 64,
          "\x1b" + "\x00" * 64, "\x1b" + ['%064x%064x' % [1, SECP256K1_ORDER]].pack('H*')].each do |signature|
          assert_raises(Hive::ArgumentError) { signer.recover_compact(@digest, signature) }
        end
        assert_raises(Hive::BaseError) { signer.sign_compact(@digest, @private_key_hex, signer.public_key('%064x' % 1)) }
      end
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
