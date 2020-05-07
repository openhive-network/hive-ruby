module Hive
  module Type
    
    # See: https://github.com/xeroc/piston-lib/blob/34a7525cee119ec9b24a99577ede2d54466fca0e/steembase/operations.py
    class Amount < BaseType
      ASSET_HBD = 'HBD'; NAI_HBD = '@@000000013'
      ASSET_HIVE = 'HIVE'; NAI_HIVE = '@@000000021'
      ASSET_VESTS = 'VESTS'; NAI_VESTS = '@@000000037'
      ASSET_TBD = 'TBD'; NAI_TBD = '@@000000013'
      ASSET_TESTS = 'TESTS'; NAI_TESTS = '@@000000021'
      VALID_ASSETS = [ASSET_HBD, ASSET_HIVE, ASSET_VESTS, ASSET_TBD, ASSET_TESTS]
      
      attr_reader :amount, :precision, :nai, :asset
      
      def self.to_h(amount)
        new(amount).to_h
      end
      
      def self.to_s(amount)
        new(amount).to_s
      end
      
      def self.to_bytes(amount)
        new(amount).to_bytes
      end
      
      def initialize(value)
        super(:amount, value)
        
        case value
        when Array
          @amount, @precision, @nai = value
          @asset = case @nai
          when NAI_HBD then ASSET_HBD
          when NAI_HIVE then ASSET_HIVE
          when NAI_VESTS then ASSET_VESTS
          else; raise TypeError, "Asset #{@nai} unknown."
          end
          
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Hash
          @amount, @precision, @nai = value.map do |k, v|
            v if %i(amount precision nai).include? k.to_sym
          end.compact
          
          @asset = case @nai
          when NAI_HBD then ASSET_HBD
          when NAI_HIVE then ASSET_HIVE
          when NAI_VESTS then ASSET_VESTS
          else; raise TypeError, "Asset #{@nai} unknown."
          end
          
          @amount = "%.#{@precision}f" % (@amount.to_f / 10 ** @precision)
        when Amount
          @precision = value.precision
          @nai = value.nai
          @asset = value.asset
          @amount = value.amount
        else
          @amount, @asset = value.strip.split(' ') rescue ['', '']
          
          # Usually, we will see unexpected 'STEEM' and 'SBD' from Hive-HF23
          # because deserialization contains them for app compatibility.
          @asset = case @asset
          when 'STEEM' then ASSET_HIVE
          when 'SBD' then ASSET_HBD
          else
            warn "Got unexpected asset: #{value}" unless VALID_ASSETS.include? @asset
            
            @asset
          end
          
          @precision = case @asset
          when ASSET_HIVE then 3
          when ASSET_VESTS then 6
          when ASSET_HBD then 3
          when ASSET_TESTS then 3
          when ASSET_TBD then 3
          else; raise TypeError, "Asset #{@asset} unknown."
          end
        end
      end
      
      def to_bytes
        asset = @asset.ljust(7, "\x00")
        amount = (@amount.to_f * 10 ** @precision).round
        
        [amount].pack('q') +
        [@precision].pack('c') +
        asset
      end
      
      def to_a
        case @asset
        when ASSET_HIVE then [(@amount.to_f * 1000).to_i.to_s, 3, NAI_HIVE]
        when ASSET_VESTS then [(@amount.to_f * 1000000).to_i.to_s, 6, NAI_VESTS]
        when ASSET_HBD then [(@amount.to_f * 1000).to_i.to_s, 3, NAI_HBD]
        end
      end
      
      def to_h
        case @asset
        when ASSET_HIVE then {
          amount: (@amount.to_f * 1000).to_i.to_s,
          precision: 3,
          nai: NAI_HIVE
        }
        when ASSET_VESTS then {
          amount: (@amount.to_f * 1000000).to_i.to_s,
          precision: 6,
          nai: NAI_VESTS
        }
        when ASSET_HBD then {
          amount: (@amount.to_f * 1000).to_i.to_s,
          precision: 3,
          nai: NAI_HBD
        }
        end
      end
      
      def to_s
        "#{@amount} #{@asset}"
      end
    end
  end
end
