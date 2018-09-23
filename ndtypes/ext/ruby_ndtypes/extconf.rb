require 'mkmf'
require_relative 'extconf_helper'

$INSTALLFILES = [
  ["ruby_ndtypes.h", "$(archdir)"]
]

["ndtypes"].each do |lib|
  dir_config(lib)
  found = find_library(lib, nil, "/home/sameer/gitrepos/plures-ruby/build/lib/")
  unless found
    PluresExtconfHelper.download_and_build_library(lib) or abort
  end
  have_library(lib)
end

["ndtypes.h"].each do |header|
  find_header(header, "/home/sameer/gitrepos/plures-ruby/build/include")
  have_header(header)
end

basenames = %w{gc_guard ruby_ndtypes}
$objs = basenames.map { |b| "#{b}.o"   }
$srcs = basenames.map { |b| "#{b}.c" }

$CFLAGS += " -O0 -g "
create_makefile("ruby_ndtypes/ruby_ndtypes")
