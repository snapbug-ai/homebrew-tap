cask "snapbug" do
  version :latest
  arch arm: "arm64", intel: "x64"

  url "https://github.com/snapbug-ai/releases/releases/latest/download/macos-#{arch}.dmg"
  name "Snapbug"
  desc "Precision debugging tool — capture state, generate AI fix PRs"
  homepage "https://snapbug.ai"

  depends_on macos: ">= :monterey"

  app "Snapbug.app"

  zap trash: [
    "~/Library/Application Support/Snapbug",
    "~/Library/Preferences/io.snapbug.desktop.plist",
    "~/Library/Caches/Snapbug",
  ]
end
