module Hive
  module ChainConfig
    EXPIRE_IN_SECS = 600
    EXPIRE_IN_SECS_PROPOSAL = 24 * 60 * 60
    
    NETWORKS_HIVE_LEGACY_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_HIVE_CHAIN_ID = 'beeab0de00000000000000000000000000000000000000000000000000000000'
    NETWORKS_HIVE_ADDRESS_PREFIX = 'STM'
    NETWORKS_HIVE_CORE_ASSET = ["0", 3, "@@000000021"] # HIVE
    NETWORKS_HIVE_DEBT_ASSET = ["0", 3, "@@000000013"] # HBD
    NETWORKS_HIVE_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_HIVE_DEFAULT_NODE = 'https://api.openhive.network'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://anyx.io'
    # NETWORKS_HIVE_DEFAULT_NODE = 'http://anyx.io'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://api.hive.blog'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://api.openhive.network'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://techcoderx.com'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://rpc.ecency.com'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://hived.privex.io'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://api.pharesim.me'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://rpc.ausbit.dev'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://hived.emre.sh'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://api.deathwing.me'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://api.c0ff33a.uk'
    # NETWORKS_HIVE_DEFAULT_NODE = 'https://hive-api.arcange.eu'
    
    NETWORKS_TEST_CHAIN_ID = '46d82ab7d8db682eb1959aed0ada039a6d49afa1602491f93dde9cac3e8e6c32'
    NETWORKS_TEST_ADDRESS_PREFIX = 'TST'
    NETWORKS_TEST_CORE_ASSET = ["0", 3, "@@000000021"] # TESTS
    NETWORKS_TEST_DEBT_ASSET = ["0", 3, "@@000000013"] # TBD
    NETWORKS_TEST_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_TEST_DEFAULT_NODE = 'https://testnet-api.openhive.network'
    # NETWORKS_TEST_DEFAULT_NODE = 'https://hive-test-beeabode.roelandp.nl'
    
    NETWORK_CHAIN_IDS = [NETWORKS_HIVE_CHAIN_ID, NETWORKS_TEST_CHAIN_ID]
  end
end
