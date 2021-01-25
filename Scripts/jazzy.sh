ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ParseSwift-iOS/Info.plist`
bundle exec jazzy \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-Swift \
  --root-url http://parseplatform.org/Parse-Swift/api/ \
  --module-version 1.1.1 \
  --theme fullwidth \
  --skip-undocumented \
  --output ./docs/api \
  --module ParseSwift \
  --swift-build-tool spm \
  --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
