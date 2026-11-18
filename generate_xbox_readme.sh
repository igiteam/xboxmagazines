
cd ~/Downloads

cat > generate-xbox-readme.sh <<'BASH'
#!/bin/bash

set -e

REPO="igiteam/xboxmagazines"
BRANCH="main"

API="https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1"
RAW="https://raw.githubusercontent.com/$REPO/refs/heads/$BRANCH"

echo "Generating PC Zone README..."

curl -fsSL "$API" | ruby -rjson -e '
data = JSON.parse(STDIN.read)
files = data["tree"].map { |item| item["path"] }

raise "GitHub tree is truncated. Cannot safely generate complete README." if data["truncated"]

directories = files
  .select { |p| p.match?(%r{_flipbook/[^/]+__page_1\.(png|jpg|jpeg)$}i) }
  .map { |p| p.split("/").first }
  .uniq

def natural_key(str)
  str.downcase.scan(/\d+|\D+/).map { |s|
    s.match?(/\A\d+\z/) ? [0, s.to_i] : [1, s]
  }
end

directories.sort_by! { |dir| natural_key(dir) }

output = []

output << "# PC Zone Magazines"
output << ""
output << "[https://igiteam.github.io/xboxmagazines/](https://igiteam.github.io/xboxmagazines/)"
output << ""
output << "[https://readme.macosxjs.com/?url=https%3A%2F%2Fgithub.com%2Figiteam%2Fxboxmagazines%2Fblob%2Fmain%2FREADME.md](https://readme.macosxjs.com/?url=https%3A%2F%2Fgithub.com%2Figiteam%2Fxboxmagazines%2Fblob%2Fmain%2FREADME.md)"
output << ""
output << "| Cover | Issue | Pages |"
output << "|-------|-------|-------|"

directories.each do |dir|
  base = dir.sub(/_flipbook$/, "")

  parts = base.split("__", 2)

  title = if parts.length == 2
    "#{parts[0].tr("_", " ")} (#{parts[1].sub(/_+$/, "").tr("_", " ")})"
  else
    base.tr("_", " ")
  end

  title = title.strip

  page_files = files.select do |path|
    path.start_with?("#{dir}/") &&
      File.basename(path).match?(/__page_\d+\.(png|jpg|jpeg)$/i)
  end

  pages = page_files.filter_map do |path|
    match = File.basename(path).match(/__page_(\d+)\.(png|jpg|jpeg)$/i)
    match[1].to_i if match
  end.uniq

  page_count = pages.length

  cover_file = page_files.find do |path|
    File.basename(path).match?(/__page_1\.(png|jpg|jpeg)$/i)
  end

  html_file = "#{dir}/#{dir}.html"

  unless cover_file && files.include?(html_file)
    warn "Skipping incomplete flipbook: #{dir}"
    next
  end

  cover = "https://raw.githubusercontent.com/igiteam/xboxmagazines/refs/heads/main/#{cover_file}"
  html = "https://html.macosxjs.com/?https://raw.githubusercontent.com/igiteam/xboxmagazines/refs/heads/main/#{html_file}"

  output << "| [![#{title}](#{cover})](#{html}) | [#{title}](#{html}) | #{page_count} |"

  puts "Added: #{title} (#{page_count} pages)"
end

File.write("README.md", output.join("\n") + "\n", encoding: "UTF-8")

puts ""
puts "======================================"
puts "PC Zone README generated successfully!"
puts "Total issues: #{output.length - 7}"
puts "File: README.md"
puts "======================================"
'

BASH

chmod +x generate-xbox-readme.sh

./generate-xbox-readme.sh
