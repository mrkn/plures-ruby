require 'mkmf'
require 'open-uri'
require 'digest/sha2'

LIBRARY_REVISIONS = {
  'ndtypes' => 'bc304fc21edc033b9e867fe31060f50ecb370e3e',
  'xnd' => 'd85217246eeef8a176210a5dcfdc9455d8403919',
  'gumath' => '0c269b20f96a51bb51b270320ad6084f2b96b83f'
}

SHA256 = {
  'gumath' => '8c61bbcc5de36aae75f42129ee5539e99f7bc0fc6d43b5b74e33442b0a3c0e79',
  'ndtypes' => '862299c7604a76d5452c4f7e4f0b293282facadd68a96b7bf4c426bc30ead2c2',
  'xnd' => 'b0b09a8ed5a96600d5c9225dce1b0b7f52e556ba4cb87e4c564dcb9c2208efb1'
}

def download(url, filename)
  FileUtils.mkdir_p(File.dirname(filename))
  open(filename, "wb") do |out|
    open(url, "rb") do |inp|
      IO.copy_stream(inp, out)
    end
  end
end

def check_sha256(libname, filename)
  expected = SHA256[libname]
  actual = Digest::SHA256.hexdigest(IO.binread(filename))
  expected == actual
end

def checkout(libname, revision, dest_dir)
  url = "https://github.com/plures/#{libname}/archive/#{revision}.zip"
  filename = File.join(dest_dir, "#{libname}.zip")
  unless File.file?(filename) && check_sha256(libname, filename)
    download(url, filename)
  end
  unless check_sha256(libname, filename)
    abort "sha256 mismatch in #{libname}-#{revision}"
  end
  system('unzip', '-xo', filename, '-d', dest_dir)
end

def build_library(libname, revision, src_dir)
  prefix = File.expand_path("../../..", __FILE__)
  cc = RbConfig.expand("$(CC)")
  cpp = RbConfig.expand("$(CPP)")
  dirname = "#{libname}-#{revision}"
  Dir.chdir(File.join(src_dir, dirname)) do
    puts "Enter #{Dir.pwd}"
    system "./configure --prefix='#{prefix}' CC='#{cc}' CPP='#{cpp}'"
    system "make"
    system "make check"
    system "make install" or abort
    append_cppflags("-I#{File.join(prefix, 'include')}")
    $LIBPATH << File.join(prefix, "lib")
  ensure
    puts "Leave #{Dir.pwd}"
  end
end

def download_and_build_library(libname)
  vendor_dir = File.expand_path("../../../vendor", __FILE__)
  revision = LIBRARY_REVISIONS[libname]
  checkout(libname, revision, vendor_dir)
  build_library(libname, revision, vendor_dir)
end

$INSTALLFILES = [
  ["ruby_ndtypes.h", "$(archdir)"]
]

["ndtypes"].each do |lib|
  dir_config(lib)
  found = find_library(lib, nil, "/home/sameer/gitrepos/plures-ruby/build/lib/")
  unless found
    download_and_build_library(lib)
    have_library(lib)
  end
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
