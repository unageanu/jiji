#!/usr/bin/ruby

$: << "../lib"

require 'rubygems'
require 'runit/testcase'
require 'runit/cui/testrunner'

require 'test_ProcessManager'
require 'test_BackTestCollector'
require 'test_Collector'
require 'test_Configuration'
require 'test_Operator'
require 'test_Output'
require 'test_Output_registry'
require 'test_OutputManager'
require 'test_Process'

require 'agent/agent_tests'
require 'dao/dao_tests'
require 'migration/migration_tests'
require 'plugin/plugin_tests'
require 'shared/shared_tests'
require 'util/util_tests'
