class Snapbug < Formula
  desc "Debug & inspect mobile apps from Chrome — CLI daemon with bundled JRE"
  homepage "https://snapbug.ai"
  version "1.0.5"
  license "Proprietary"

  # Apple Silicon only: Intel builds stopped after 1.0.2 (see release.yml).
  depends_on arch: :arm64

  url "https://github.com/snapbug-ai/releases/releases/download/cli-v#{version}/snapbug-macos-arm64.tar.gz"
  sha256 "5fc448ca98c823be1aa6cc12a2f99edd48c4fe867f311df9bc8c9098640b624e"

  # This formula supersedes snapbug-cli, which owned the same symlink. Without this,
  # anyone who installed the old name gets a successful install whose `snapbug`
  # command still points at the old Cellar.
  link_overwrite "bin/snapbug"

  def install
    # The tarball is a jpackage app-image with an embedded JRE (no openjdk dependency).
    prefix.install Dir["*"]
    launcher = Dir["#{prefix}/**/snapbug", "#{prefix}/**/Snapbug"].find do |p|
      File.file?(p) && (p.include?("/bin/") || p.include?("/MacOS/"))
    end
    odie "snapbug launcher not found in tarball" unless launcher

    # Not a symlink: the jpackage launcher locates snapbug.cfg and its bundled runtime
    # relative to how it was invoked, so reaching it through Homebrew's symlink chain
    # sends it looking beside the symlink and it dies with
    #   Error opening ".../Cellar/snapbug/Contents/app/snapbug.cfg": No such file
    # Exec it by absolute path. opt_prefix rather than prefix, so the wrapper survives
    # version bumps.
    relative = Pathname.new(launcher).relative_path_from(prefix)
    (bin/"snapbug").write <<~SH
      #!/bin/bash
      exec "#{opt_prefix}/#{relative}" "$@"
    SH
    (bin/"snapbug").chmod 0755
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
