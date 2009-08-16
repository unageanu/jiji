
require 'jiji/plugin/securities_plugin'
require 'test_utils'

JIJI::Plugin.register( 
  JIJI::Plugin::SecuritiesPlugin::FUTURE_NAME, 
  Test::MockClient.new )