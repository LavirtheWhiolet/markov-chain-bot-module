require 'strscan'

# ---- Properties ----

BUILD_DIR = "build"
PEG2RB = "#{BUILD_DIR}/peg2rb.rb"

# ---- Utilities (part 1) ----

class FileList
  
  include Rake::DSL
  
  # Example:
  #   
  #   FileList["*.cpp"].to { |x| x.ext(".o") }.doing do |cpp, obj|
  #     sh "gcc -o #{obj} -c #{cpp}"
  #   end
  #
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

# ---- Tasks ----

RB_FILES =
  FileList["*.rb"].to { |f| "#{BUILD_DIR}/lib/#{f}" }.doing do |src_file, dest_file|
    cp_p src_file, dest_file
  end +
  FileList["*.peg"].to { |f| "#{BUILD_DIR}/lib/#{f.ext(".rb")}" }.doing do |src_file, dest_file|
    peg2rb src_file, dest_file
  end

README_FILES =
  FileList["README.md"].to { |_| "#{BUILD_DIR}/README" }.doing do |src_file, dest_file|
    File.translate src_file, dest_file do |content|
      content.exclude("<!-- exclude from gem -->", "<!-- end -->") do |b, e|
        STDERR.puts %(WARNING: no #{b}...#{e} is found in #{src_file})
      end.
      markdown_sections.map do |section|
        "#{"=" * (section.depth + 1)} #{section.name}\n\n#{section.content}\n\n"
      end.join.
      gsub(/^    /, "  ").
      exclude("<!--", "-->")
    end
  end

GEMSPEC_FILES =
  FileList["README.md"].to { |_| "#{BUILD_DIR}/gemspec" }.doing do |src_file, dest_file|
    File.translate src_file, dest_file do |content|
      credits_section = content.markdown_section("Credits") or raise %(section "Credits" must be present in #{src_file})
      credits = credits_section.content.to_h
      credits_get = lambda do |key|
        credits[key] or raise %("#{key}" is not found in section "Credits" of "#{src_file}")
      end
      <<-GEMSPEC
        Gem::Specification.new do |s|
          s.name = #{credits_get["Gem name"].to_rb}
          s.version = #{credits_get["Version"].to_rb}
          s.license = #{credits_get["License"].to_rb}
          s.summary = #{content.markdown_sections.first.name.to_rb}
          s.description = #{content.markdown_sections.first.content.
            exclude("<!--", "-->").strip.to_rb}
          s.authors = #{credits_get["Authors"].split(/\s*,\s*/).to_rb}
          s.email = #{credits_get["E-mail"].to_rb}
          s.files = #{(RB_FILES + README_FILES).lchomp_dir(BUILD_DIR).to_rb}
          s.extra_rdoc_files = #{README_FILES.lchomp_dir(BUILD_DIR).to_rb}
          s.homepage = #{credits_get["Homepage"].to_rb}
        end
      GEMSPEC
    end
  end

desc "build Ruby gem"
task :gem => (RB_FILES + README_FILES + GEMSPEC_FILES) do
  Dir.chdir BUILD_DIR do
    sh "gem build #{GEMSPEC_FILES.lchomp_dir(BUILD_DIR).join(" ")}"
  end
  FileList["#{BUILD_DIR}/*.gem"].each { |file| mv file, BUILD_DIR }
end

task :default => :gem

desc "remove all generated files"
task :clean do
  files =
    FileList["#{BUILD_DIR}/*"] - FileList[PEG2RB] + FileList["*.gem"] +
    FileList["doc"]
  files.each do |entry|
    rm_r entry
  end
end

file "doc" => (RB_FILES + README_FILES) do
  sh "rdoc -o doc -m #{README_FILES.first} \
    #{(RB_FILES + README_FILES).join(" ")}"
end

# ---- Utilities (part 2) ----

class FileList
  
  def lchomp_dir(dir)
    dir = dir.chomp("/") + "/"
    self.map { |file| file.lchomp dir }
  end
  
end

class File
  
  # reads +src_file+, processes it with +src_content_func+ and writes the result
  # to +dest_file+.
  def self.translate(src_file, dest_file, &src_content_func)
    File.write(dest_file, src_content_func.(File.read(src_file)))
  end
  
end

class Object
  
  # Ruby code representing this Object.
  def to_rb
    inspect
  end
  
end

class String
  
  def lchomp(prefix)
    if self.start_with? prefix then self[prefix.length..-1]
    else self
    end
  end
             
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
        result.last.content << content)
    end
    result.drop(1)
  end
  
  # returns specified MarkdownSection from this String or nil.
  def markdown_section(name)
    markdown_sections.find { |s| s.name == name }
  end
  
  # excludes everything between +start_string+ and +end_string+ (including) from
  # this String. If +warning_func+ is specified and nothing to exclude is
  # found then +warning_func+ is passed with +start_string+ and +end_string+.
  def exclude(start_string, end_string, &func_if_not_found)
    exclusion_regexp = Regexp.new(
      Regexp.escape(start_string) + ".*?" + Regexp.escape(end_string),
      Regexp::MULTILINE
    )
    func_if_not_found.(start_string, end_string) if
      func_if_not_found and not exclusion_regexp === self
    return self.gsub(exclusion_regexp, "")
  end
  
  def to_h
    self.
      lines.
      map do |line|
        entry = line.chomp.split(/\s*\:\s*/, 2)
        if entry.size == 2 then entry
        else nil
        end
      end.
      compact.
      to_h
  end
  
  class MarkdownSection < Struct.new(:name, :depth, :content); end
  
end

module Enumerable
  
  # Backport from higher versions of Ruby.
  def to_h
    reduce({}) { |result, entry| result[entry[0]] = entry[1]; result }
  end
  
end

def peg2rb src_file, dest_file
  mkdir_p File.dirname(dest_file)
  retries = 0
  begin
    sh "ruby #{PEG2RB} #{src_file} > #{dest_file}"
  rescue
    case retries
    when 0
      STDERR.puts %(It looks like "#{PEG2RB}" is not present. I will try to download it for you.)
      sh "wget -O#{PEG2RB} https://raw.githubusercontent.com/LavirtheWhiolet/self-bootstrap/master/peg2rb.rb"
      retries += 1
      retry
    else
      raise %("#{PEG2RB}" is not present)
    end
  end
end

# The same as #cp() but creates destination directory if it does not exist.
def cp_p source_file, dest_file
  mkdir_p File.dirname(dest_file)
  cp source_file, dest_file
end
