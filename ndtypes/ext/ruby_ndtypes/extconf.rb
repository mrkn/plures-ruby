require 'mkmf'
require_relative 'extconf_helper'

$INSTALLFILES = [
  ["ruby_ndtypes.h", "$(archdir)"]
]

dir_config('ndtypes')
found = find_library('ndtypes', nil, "/home/sameer/gitrepos/plures-ruby/build/lib/")
unless found
  prefix = File.expand_path("../../..", __FILE__)
  vendor_dir = File.join(prefix, 'vendor')
  PluresExtconfHelper.download_and_build_library(
    'ndtypes', prefix, vendor_dir
  ) or abort
end
have_library('ndtypes')

["ndtypes.h"].each do |header|
  find_header(header, "/home/sameer/gitrepos/plures-ruby/build/include")
  have_header(header)
end

basenames = %w{gc_guard ruby_ndtypes}
$objs = basenames.map { |b| "#{b}.o"   }
$srcs = basenames.map { |b| "#{b}.c" }

$CFLAGS += " -O0 -g "
create_makefile("ruby_ndtypes/ruby_ndtypes")
