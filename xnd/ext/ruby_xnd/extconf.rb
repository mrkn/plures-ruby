require 'mkmf'

ndtypes_version = ">= 0.0.1.rc1"
ndtypes_spec = Gem::Specification.find_by_name("ndtypes", ndtypes_version)
ndtypes_extdir = File.join(ndtypes_spec.gem_dir, 'ext', 'ruby_ndtypes')
ndtypes_includedir = File.join(ndtypes_spec.gem_dir, 'include')
ndtypes_libdir = File.join(ndtypes_spec.gem_dir, 'lib')

require File.join(ndtypes_extdir, 'extconf_helper')

# libndtypes

dir_config('ndtypes')
find_library('ndtypes', nil, ndtypes_libdir, "/home/sameer/gitrepos/plures-ruby/build/lib/")
have_library('ndtypes')

# libxnd

found = find_library('xnd', nil, "/home/sameer/gitrepos/plures-ruby/build/lib/")
unless found
  prefix = File.expand_path("../../..", __FILE__)
  vendor_dir = File.join(prefix, 'vendor')
  success = PluresExtconfHelper.download_and_build_library(
    'xnd', prefix, vendor_dir,
    configure_opts: {
      '--with-includes' => ndtypes_includedir,
      '--with-libs' => ndtypes_libdir,
    }
  )
  abort unless success
end
have_library('xnd')

["ndtypes.h", "xnd.h", "ruby_ndtypes.h"].each do |header|
  find_header(header, ndtypes_includedir, ndtypes_extdir, "/home/sameer/gitrepos/plures-ruby/build/include")
  have_header(header)
end

basenames = %w{float_pack_unpack gc_guard ruby_xnd}
$objs = basenames.map { |b| "#{b}.o"   }
$srcs = basenames.map { |b| "#{b}.c" }

$CFLAGS += " -fPIC -g -Wno-undef "
create_makefile("ruby_xnd/ruby_xnd")
