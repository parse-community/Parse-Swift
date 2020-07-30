ver=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ParseSwift-iOS/Info.plist`
jazzy \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-Swift \
  --root-url http://parseplatform.org/Parse-Swift/api/ \
  --module-version ${ver} \
  --theme fullwidth \
  --skip-undocumented \
  --module ParseSwift \
  --swift-build-tool spm \
  --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
