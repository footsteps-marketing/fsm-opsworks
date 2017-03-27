require 'chefspec'
require 'chefspec/berkshelf'

require 'helper_functions'

#Dir["libraries/*.rb"].each { |file| require File.expand_path(file) }
$LOAD_PATH.unshift('libraries')
