cask "instantly" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/duongductrong/Instantly/releases/download/v#{version}/Instantly-v#{version}.dmg"
  name "Instantly"
  desc "AI assistant for macOS"
  homepage "https://github.com/duongductrong/Instantly"

  auto_updates true

  app "Instantly.app"

  zap trash: [
    "~/Library/Application Support/com.duongductrong.Instantly",
    "~/Library/Preferences/com.duongductrong.Instantly.plist",
    "~/Library/Saved Application State/com.duongductrong.Instantly.savedState",
  ]
end
