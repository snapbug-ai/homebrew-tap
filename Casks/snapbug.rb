cask "snapbug" do
  version "1.0.0"

  on_arm do
    url "https://github.com/snapbug-ai/releases/releases/download/#{version}/macos-arm64.dmg"
    sha256 "f140fe85bec138fa355c0e7cd95c4d6578a516348b310c0a3140497319154f37"
  end

  on_intel do
    url "https://github.com/snapbug-ai/releases/releases/download/#{version}/macos-x64.dmg"
    sha256 "5ee080e9ccb5d19552b21ad14eab25aca281cbe4233148a569820c090f109dc3"
  end

  name "Snapbug"
  desc "Desktop companion for debugging mobile apps in real-time"
  homepage "https://snapbug.ai"

  app "Snapbug.app"

  zap trash: [
    "~/Library/Application Support/Snapbug",
    "~/Library/Preferences/io.snapbug.sdk.plist",
    "~/Library/Caches/Snapbug",
  ]
end
