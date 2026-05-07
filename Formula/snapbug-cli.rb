class SnapbugCli < Formula
  desc "Debug & inspect mobile apps from Chrome - CLI daemon for AI fix, build, PR"
  homepage "https://snapbug.ai"
  version "0.1.0"

  url "https://github.com/nickolasmv/Snapbug/releases/download/cli-v#{version}/snapbug-cli.jar"
  sha256 "319f35b5f50c99c2d12c69f93ce5fa526b377b1046b901ac0a486f150bf516c6"

  depends_on "openjdk@21"

  def install
    libexec.install "snapbug-cli.jar"
    (bin/"snapbug").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk@21"].opt_bin}/java" -jar "#{libexec}/snapbug-cli.jar" "$@"
    EOS
  end

  def caveats
    <<~EOS
      Snapbug CLI daemon provides AI-powered bug fixing for mobile apps.

      Usage:
        snapbug serve    # Start daemon (ports 9023, 9024, 9090)
        snapbug status   # Check if running
        snapbug stop     # Stop daemon

      The Chrome Extension auto-discovers the CLI at localhost:9090.
      Install the extension from Chrome Web Store for the full experience.
    EOS
  end

  test do
    output = shell_output("#{bin}/snapbug status 2>&1")
    assert_match(/not running|running/, output)
  end
end
