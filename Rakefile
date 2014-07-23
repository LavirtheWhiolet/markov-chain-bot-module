require 'yaml'
require 'strscan'

BUILD_DIR = "build"

module DSL2
  
  include Rake::DSL
  
  def to(&rename_func)
    self.map do |src_file|
      [src_file, rename_func.(src_file)]
    end
  end
  
  def doing(&action)
    self.map do |src_and_dest_file|
      src_file, dest_file = *src_and_dest_file
      file dest_file => src_file do
        action.(src_file, dest_file)
      end
      dest_file
    end
  end
  
end

class FileList; include DSL2; end
class Array; include DSL2; end

GEM_FILES =
  FileList["*.rb"].to { |f| "#{BUILD_DIR}/lib/#{f}" }.doing do |src_file, dest_file|
    cp_p src_file, dest_file
  end +
  FileList["*.peg"].to { |f| "#{BUILD_DIR}/lib/#{f.ext(".peg")}" }.doing do |src_file, dest_file|
    peg2rb src_file, dest_file
  end +
  ["README.md"].to { |_| "#{BUILD_DIR}/README" }.doing do |src_file, dest_file|
    excluded_regexp = Regexp.new(
      Regexp.escape("<!-- exclude from gem -->") +
      ".*?" +
      Regexp.escape("<!-- end -->"),
      Regexp::MULTILINE
    )
    src_file_content = File.read src_file
    STDERR.puts %(WARNING: no #{excluded_regexp} is found in "#{src_file}") unless excluded_regexp === src_file_content
    mkdir_p File.basename(dest_file)
    File.write dest_file, src_file_content.
      gsub!(excluded_regexp, "").
      gsub!(/^\#+/) { |match| "=" * match.length }.
      gsub!(/^ +/) { |match| " " * (match.length / 2) }
  end +
  ["README.md"].to { |_| "#{BUILD_DIR}/gemspec" }.doing do |src_file, dest_file|
    src_file_content = File.read src_file
    bureaucracy = src_file_content[/^#+\s+Bureaucracy(.*?)^#/m, 1] or raise %(section "Bureaucracy" is not found in "#{src_file}")
    bureaucracy = YAML.load bureaucracy
    summary_and_description = src_file_content[/^#\s+(.*?$.*?)#/m, 1] or raise %("#{src_file}" must have a main section ("# Foobar") named after this package)
    summary = summary_and_description.lines.first
    description = summary_and_description.lines.drop(1).join
    File.write dest_file, <<-GEMSPEC
      Gem::Specification.new do |s|
        s.name        = '#{bureaucracy["Gem name"] or raise %(no gem name is specified in "#{src_file}")}'
        s.version     = '#{bureaucracy["Version"] or raise %(no version is specified in "#{src_file}")}'
        s.licenses    = ['#{bureaucracy["License"] or raise %(no license is specified in "#{src_file}")}']
        s.summary     = "#{summary}"
        s.description = "#{description}"
        s.authors     = #{[`git config user.name`].inspect}
        s.email       = 'Lavir.th.Whiolet@gmail.com'
        s.files       = ["markov_chain.rb"]
        s.homepage    = 'https://github.com/LavirtheWhiolet/markov-chain-bot-module'
      end
    GEMSPEC
  end

class String
  
  # MarkdownSection-s of this MarkdownText
  def markdown_sections
    s = StringScanner.new(self)
    result = [MarkdownSection.new(nil, 0, "")]
    until s.eos?
      pos = s.pos
      (s.pos = pos and name = s.scan(/.*\n/) and s.scan(/^\=+\n/) and
        result << MarkdownSection.new(name.strip, 0, "")) or
      (s.pos = pos and name = s.scan(/.*\n/) and s.scan(/^\-+\n/) and
        result << MarkdownSection.new(name.strip, 1, "")) or
      (s.pos = pos and depth_str = s.scan(/#+/) and s.scan(/\s*/) and name = s.scan(/.*\n/) and
        result << MarkdownSection.new(name.strip, depth_str.length, "")) or
      (s.pos = pos and content = s.scan(/.*\n?/) and
        result.last.content << content.strip)
    end
    result.drop(1)
  end
  
  class MarkdownSection < Struct.new(:name, :depth, :content); end
  
end

def peg2rb src_file, dest_file
  mkdir_p File.basename(dest_file)
  retries = 0
  begin
    sh "ruby peg2rb.rb #{src_file} > #{dest_file}"
  rescue
    case retries
    when 0
      STDERR.puts "It looks like peg2rb is not installed. Trying to install it..."
      sh "wget -Opeg2rb.rb https://github.com/LavirtheWhiolet/self-bootstrap/blob/master/peg2rb.rb"
      retries += 1
      retry
    else
      raise "peg2rb is not installed"
    end
  end
end

# The same as #cp() but creates destination directory if it does not exist.
def cp_p source_file, dest_file
  mkdir_p File.basename(dest_file)
  cp source_file, dest_file
end