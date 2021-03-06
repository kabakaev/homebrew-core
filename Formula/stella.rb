class Stella < Formula
  desc "Atari 2600 VCS emulator"
  homepage "https://stella-emu.github.io/"
  url "https://github.com/stella-emu/stella/releases/download/5.1/stella-5.1-src.tar.xz"
  sha256 "96a5ed7aa27f29e6af3643bf4af08e0441d46c1b3f47f0d0c55fa6f0e41f407b"
  head "https://github.com/stella-emu/stella.git"

  bottle do
    cellar :any
    sha256 "093b02aaaa58d1c1f7bd7201a656ac69df50d306b7011193fc10de827723eaaf" => :high_sierra
    sha256 "b78d5aa2ff5db099882e179fa73d69f61dd7acbf750f957a0405baf0dad605e2" => :sierra
    sha256 "fd46790269b9de0c95168d5ac0638c4d340fa4f7f93a47e9a8822966dad847d1" => :el_capitan
    sha256 "38750b16e6dd2efaad0b6adb01999f6f9c49a5924e5d6a347aecc375134fdc67" => :x86_64_linux
  end

  needs :cxx14

  depends_on :xcode => :build if OS.mac?
  depends_on "sdl2"
  depends_on "libpng"
  depends_on "zlib" unless OS.mac?
  # Stella is using c++14
  fails_with :gcc => "4.8" unless OS.mac?

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j16" if ENV["CIRCLECI"]

    sdl2 = Formula["sdl2"]
    libpng = Formula["libpng"]
    if OS.mac?
      cd "src/macosx" do
        inreplace "stella.xcodeproj/project.pbxproj" do |s|
          s.gsub! %r{(\w{24} \/\* SDL2\.framework)}, '//\1'
          s.gsub! %r{(\w{24} \/\* png)}, '//\1'
          s.gsub! /(HEADER_SEARCH_PATHS) = \(/,
                  "\\1 = (#{sdl2.opt_include}/SDL2, #{libpng.opt_include},"
          s.gsub! /(LIBRARY_SEARCH_PATHS) = ("\$\(LIBRARY_SEARCH_PATHS\)");/,
                  "\\1 = (#{sdl2.opt_lib}, #{libpng.opt_lib}, \\2);"
          s.gsub! /(OTHER_LDFLAGS) = "((-\w+)*)"/, '\1 = "-lSDL2 -lpng \2"'
        end
        xcodebuild "SYMROOT=build"
        prefix.install "build/Release/Stella.app"
        bin.write_exec_script "#{prefix}/Stella.app/Contents/MacOS/Stella"
      end
    else
      system "./configure", "--prefix=#{prefix}",
                            "--bindir=#{bin}",
                            "--with-sdl-prefix=#{sdl2.prefix}",
                            "--with-libpng-prefix=#{libpng.prefix}",
                            "--with-zlib-prefix=#{Formula["zlib"].prefix}"
      system "make", "install"
    end
  end

  test do
    assert_match /Stella version #{version}/, shell_output("#{bin}/Stella -help").strip if OS.mac?
    # Test is disabled for Linux, as it is failing with:
    # ERROR: Couldn't load settings file
    # ERROR: Couldn't initialize SDL: No available video device
    # ERROR: Couldn't create OSystem
    # ERROR: Couldn't save settings file
  end
end
