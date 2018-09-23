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

def check_message_for(m)
  f = caller[0][/in `([^<].*)'$/, 1] and f << ": " #` for vim #'
  m = "#{m}... "
  message "%s", m
  a = r = nil
  Logging::postpone do
    r = yield
    a = (r ? "yes" : "no")
    "#{f}#{m}-------------------- #{a}\n\n"
  end
  message "%s\n", a
  Logging::message "--------------------\n\n"
  r
end

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

  check_message_for("downloading #{libname} revision #{revision}") do
    unless File.file?(filename) && check_sha256(libname, filename)
      download(url, filename)
    end
    if check_sha256(libname, filename)
      true
    else
      $stderr.puts "SHA256 mismatch in #{libname}"
      false
    end
  end
end

def build_library(libname, revision, src_dir, prefix)
  cc = RbConfig.expand("$(CC)")
  cpp = RbConfig.expand("$(CPP)")
  dirname = "#{libname}-#{revision}"
  Dir.chdir(File.join(src_dir, dirname)) do
    puts "Enter #{Dir.pwd}"
    system "./configure --prefix='#{prefix}' CC='#{cc}' CPP='#{cpp}'" or return false
    system "make" or return false
    system "make check" or return false
    system "make install" or return false
  ensure
    puts "Leave #{Dir.pwd}"
  end
  true
end

def check_build_library(libname, revision, src_dir)
  prefix = File.expand_path("../../..", __FILE__)
  includedir = File.join(prefix, 'include')
  libdir = File.join(prefix, "lib")

  success = check_message_for "building #{libname} " do
    build_library(libname, revision, src_dir, prefix)
  end

  if success
    append_cppflags("-I#{includedir}")
    append_ldflags("-Wl,-rpath #{libdir}")
    $LIBPATH << libdir
    $libs = append_library($libs, libname)
  end
end

def download_and_build_library(libname, headername=nil)
  vendor_dir = File.expand_path("../../../vendor", __FILE__)
  revision = LIBRARY_REVISIONS[libname]
  checkout(libname, revision, vendor_dir) and
    check_build_library(libname, revision, vendor_dir)
end

$INSTALLFILES = [
  ["ruby_ndtypes.h", "$(archdir)"]
]

["ndtypes"].each do |lib|
  dir_config(lib)
  found = find_library(lib, nil, "/home/sameer/gitrepos/plures-ruby/build/lib/")
  unless found
    download_and_build_library(lib) or abort
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
