class SnapbugCli < Formula
  desc "Debug & inspect mobile apps from Chrome - CLI daemon for AI fix, build, PR"
  homepage "https://snapbug.ai"
  version "0.1.0"

  url "https://github.com/nickolasmv/Snapbug/releases/download/cli-v#{version}/snapbug-cli.jar"
  sha256 "319f35b5f50c99c2d12c69f93ce5fa526b377b1046b901ac0a486f150bf516c6"

  depends_on "openjdk@21"

  service do
    run [opt_bin/"snapbug", "serve"]
    keep_alive true
    log_path var/"log/snapbug-cli.log"
    error_log_path var/"log/snapbug-cli.log"
    process_type :background
  end

  def install
    libexec.install "snapbug-cli.jar"
    (bin/"snapbug").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk@21"].opt_bin}/java" -jar "#{libexec}/snapbug-cli.jar" "$@"
    EOS

    # Native Messaging Host launcher
    (libexec/"snapbug-native-host.sh").write <<~EOS
      #!/bin/bash
      read_message() {
        local len_bytes
        len_bytes=\\$(dd bs=4 count=1 2>/dev/null | od -An -tu4 -N4 | tr -d ' ')
        if [ -z "\\$len_bytes" ] || [ "\\$len_bytes" -eq 0 ]; then return 1; fi
        dd bs="\\$len_bytes" count=1 2>/dev/null
      }
      write_message() {
        local msg="\\$1" len=\\${#msg}
        printf "\\$(printf '\\\\\\\\x%02x\\\\\\\\x%02x\\\\\\\\x%02x\\\\\\\\x%02x' \\$((len&0xFF)) \\$(((len>>8)&0xFF)) \\$(((len>>16)&0xFF)) \\$(((len>>24)&0xFF)))"
        printf '%s' "\\$msg"
      }
      MSG=\\$(read_message) || exit 0
      ACTION=\\$(echo "\\$MSG" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
      if [ "\\$ACTION" = "start" ]; then
        if curl -s --connect-timeout 1 http://localhost:9090/api/status >/dev/null 2>&1; then
          write_message '{"started":true,"already_running":true}'; exit 0
        fi
        SNAPBUG_BIN="#{bin}/snapbug"
        nohup "\\$SNAPBUG_BIN" serve > /tmp/snapbug-cli.log 2>&1 &
        write_message '{"started":true,"pid":'"\\$!"'}'
      else
        write_message '{"error":"unknown action"}'
      fi
    EOS
    chmod 0755, libexec/"snapbug-native-host.sh"
  end

  def post_install
    native_host_dir = if OS.mac?
      Pathname.new(Dir.home)/"Library/Application Support/Google/Chrome/NativeMessagingHosts"
    else
      Pathname.new(Dir.home)/".config/google-chrome/NativeMessagingHosts"
    end
    native_host_dir.mkpath

    manifest = {
      "name" => "io.snapbug.cli",
      "description" => "Snapbug CLI launcher",
      "path" => (libexec/"snapbug-native-host.sh").to_s,
      "type" => "stdio",
      "allowed_origins" => ["chrome-extension://PLACEHOLDER_EXTENSION_ID/"],
    }

    (native_host_dir/"io.snapbug.cli.json").write(JSON.generate(manifest))
  end

  def caveats
    <<~EOS
      Snapbug CLI daemon provides AI-powered bug fixing for mobile apps.

      Usage:
        snapbug serve    # Start daemon (ports 9023, 9024, 9090)
        snapbug status   # Check if running
        snapbug stop     # Stop daemon

      To start automatically at login:
        brew services start snapbug-ai/tap/snapbug-cli

      The Chrome Extension auto-discovers the CLI at localhost:9090.
    EOS
  end

  test do
    output = shell_output("#{bin}/snapbug status 2>&1")
    assert_match(/not running|running/, output)
  end
end
