ver=`cat ParseSwift.xcodeproj/project.pbxproj | grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | tr -d ';' | tr -d ' '`
bundle exec jazzy \
  --clean \
  --author "Parse Community" \
  --author_url http://parseplatform.org \
  --github_url https://github.com/parse-community/Parse-Swift \
  --root-url http://parseplatform.org/Parse-Swift/api/ \
  --module-version ${ver} \
  --theme fullwidth \
  --skip-undocumented \
  --output ./docs/api \
  --module ParseSwift \
  --swift-build-tool spm \
  --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
