module Hive
  class CompactSigner
    HEADER_BASE = 27
    COMPRESSED_FLAG = 4
    ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

    class Rbsecp256k1 < CompactSigner

      def initialize
        require 'rbsecp256k1'

        unless Secp256k1.have_recovery?
          raise LoadError, 'rbsecp256k1 was built without recoverable signature support'
        end

        @context = Secp256k1::Context.create
      end

      def sign_compact(digest32, private_key_hex, public_key_hex = nil, compressed = false)
        validate_digest(digest32)
        validate_private_key(private_key_hex)
        private_key = Secp256k1::PrivateKey.from_data([private_key_hex].pack('H*'))
        signature = @context.sign_recoverable(private_key, digest32)
        compact_signature, recovery_id = signature.compact
        header = HEADER_BASE + recovery_id + (compressed ? COMPRESSED_FLAG : 0)
        compact = [header].pack('C') + compact_signature

        check_public_key(digest32, compact, public_key_hex)
      end

      def recover_compact(digest32, compact_signature)
        validate_digest(digest32)
        validate_signature(compact_signature)
        header = compact_signature.bytes.first
        recovery_id = header - HEADER_BASE
        recovery_id -= COMPRESSED_FLAG if recovery_id >= COMPRESSED_FLAG
        signature = @context.recoverable_signature_from_compact(compact_signature.byteslice(1, 64), recovery_id)

        key = signature.recover_public_key(digest32)
        (header >= HEADER_BASE + COMPRESSED_FLAG ? key.compressed : key.uncompressed).unpack1('H*')
      end

      def public_key(private_key_hex, compressed = false)
        validate_private_key(private_key_hex)
        keypair = @context.key_pair_from_private_key([private_key_hex].pack('H*'))
        public_key = keypair.public_key

        (compressed ? public_key.compressed : public_key.uncompressed).unpack1('H*')
      end
    end

    class PureRuby < CompactSigner
      def initialize
        require 'ecdsa'
        require 'securerandom'
        @group = ECDSA::Group::Secp256k1
      end

      def sign_compact(digest32, private_key_hex, public_key_hex = nil, compressed = false)
        validate_digest(digest32)
        validate_private_key(private_key_hex)
        signature = nil
        until signature
          # A fresh CSPRNG nonce is essential: reuse exposes the private key.
          nonce = 1 + SecureRandom.random_number(ORDER - 1)
          signature = ECDSA.sign(@group, private_key_hex.to_i(16), digest32, nonce)
        end

        point = @group.new_point(nonce)
        recovery_id = (point.y & 1) | (point.x >= ORDER ? 2 : 0)
        s = signature.s
        if s > ORDER / 2
          s = ORDER - s
          recovery_id ^= 1
        end
        header = HEADER_BASE + recovery_id + (compressed ? COMPRESSED_FLAG : 0)
        compact = [header].pack('C') + ['%064x%064x' % [signature.r, s]].pack('H*')
        check_public_key(digest32, compact, public_key_hex)
      end

      def recover_compact(digest32, compact_signature)
        validate_digest(digest32)
        validate_signature(compact_signature)
        header = compact_signature.getbyte(0) - HEADER_BASE
        recovery_id = header & 3
        r, s = compact_signature.byteslice(1, 64).unpack('H64H64').map { |hex| hex.to_i(16) }
        x = r + (recovery_id >> 1) * ORDER
        encoded_point = [2 + (recovery_id & 1)].pack('C') + ['%064x' % x].pack('H*')
        point = ECDSA::Format::PointOctetString.decode(encoded_point, @group)
        # SEC1 4.1.6: Q = r^-1 (sR - eG). Curve decoding validates R.
        inverse_r = ECDSA::PrimeField.new(ORDER).inverse(r)
        key = point.multiply_by_scalar(s).
          add_to_point(@group.new_point(-digest32.unpack1('H*').to_i(16) % ORDER)).
          multiply_by_scalar(inverse_r)
        raise Hive::ArgumentError, 'Compact signature recovered the point at infinity' if key.infinity?

        ECDSA::Format::PointOctetString.encode(key, compression: header >= COMPRESSED_FLAG).unpack1('H*')
      rescue ECDSA::Format::DecodeError => e
        raise Hive::ArgumentError, e.message
      end

      def public_key(private_key_hex, compressed = false)
        validate_private_key(private_key_hex)
        key = @group.new_point(private_key_hex.to_i(16))
        ECDSA::Format::PointOctetString.encode(key, compression: compressed).unpack1('H*')
      end
    end

    def self.default
      @default ||= begin
        Rbsecp256k1.new
      rescue LoadError
        PureRuby.new
      end
    end

  private
    def validate_digest(digest)
      unless digest.is_a?(String) && digest.bytesize == 32
        raise Hive::ArgumentError, 'Digest must be a 32-byte string'
      end
    end

    def validate_private_key(key)
      unless key.is_a?(String) && /\A[0-9a-fA-F]{64}\z/.match?(key) && (1...ORDER).cover?(key.to_i(16))
        raise Hive::ArgumentError, 'Private key must be a 32-byte hex scalar in the secp256k1 range'
      end
    end

    def validate_signature(signature)
      unless signature.is_a?(String) && signature.bytesize == 65 && (27..34).cover?(signature.getbyte(0)) &&
          signature.byteslice(1, 64).unpack('H64H64').all? { |hex| (1...ORDER).cover?(hex.to_i(16)) }
        raise Hive::ArgumentError, 'Invalid compact signature'
      end
    end

    def check_public_key(digest, signature, public_key)
      if public_key && public_key != recover_compact(digest, signature)
        raise Hive::BaseError, 'Compact signature recovered unexpected public key'
      end
      signature
    end
  end
end
