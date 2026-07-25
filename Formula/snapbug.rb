class Snapbug < Formula
  desc "Debug & inspect mobile apps from Chrome — CLI daemon with bundled JRE"
  homepage "https://snapbug.ai"
  version "0.1.1"
  license "Proprietary"

  on_macos do
    on_arm do
      url "https://github.com/snapbug-ai/releases/releases/download/cli-v#{version}/snapbug-macos-arm64.tar.gz"
      sha256 "8fda58c6fa7bcd5e5bb5add2a0d97a0657ca684f689da89e2aeafcf7dd832cde"
    end
    on_intel do
      url "https://github.com/snapbug-ai/releases/releases/download/cli-v#{version}/snapbug-macos-x64.tar.gz"
      sha256 "7489966f06babe5acf7e28cf6e7d8bfeb3691a938305e207f99fbf4679e291d3"
    end
  end

  def install
    # The tarball is a jpackage app-image with an embedded JRE (no openjdk dependency).
    prefix.install Dir["*"]
    launcher = Dir["#{prefix}/**/snapbug", "#{prefix}/**/Snapbug"].find do |p|
      File.file?(p) && (p.include?("/bin/") || p.include?("/MacOS/"))
    end
    odie "snapbug launcher not found in tarball" unless launcher
    bin.install_symlink launcher => "snapbug"
  end

  service do
    run [opt_bin/"snapbug", "serve"]
    keep_alive true
    log_path var/"log/snapbug-cli.log"
    error_log_path var/"log/snapbug-cli.log"
    process_type :background
  end

  def caveats
    <<~EOS
      Snapbug CLI daemon bundles its own Java runtime — no JDK needed.

      Start at login:
        brew services start snapbug-ai/tap/snapbug
      Manual control:
        snapbug serve | status | stop | pair

      The Chrome extension / browser inspector auto-discovers the daemon at
      http://localhost:9090.

      This build is unsigned. If macOS blocks first launch, run:
        xattr -dr com.apple.quarantine "$(brew --prefix)/opt/snapbug"
    EOS
  end

  test do
    assert_match(/not running|running/, shell_output("#{bin}/snapbug status 2>&1"))
  end
end
