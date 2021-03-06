# encoding: UTF-8

require 'json'
require 'open-uri'

class Downloader
  def initialize(target_dir, urls)
    @target_dir = target_dir
    @urls = urls
    @failed = []
  end

  def run
    @urls.each_with_index do |url, index|
      print "\rDownloading #{index + 1} of #{@urls.size}"
      download_url(@target_dir, url)
    end
    print "\n"
    print_errors
  end

  private
  def download_url(target_dir, url)
    path = File.join(target_dir, url.slice(/([^\/]+)$/, 1))
    open(url) do |stream|
      File.open(path, 'wb') { |file| file.puts(stream.read) }
    end unless File.exists?(path)
  rescue OpenURI::HTTPError
    @failed << url
  end

  def print_errors
    unless @failed.empty?
      puts ''
      puts 'The following could not be downloaded:'
      @failed.each_with_index { |url, index| puts "#{index + 1}. #{url}" }
    end
  end
end

USAGE_NOTE = 'Usage: ruby downloader.rb input.json path_to_folder'
abort(USAGE_NOTE) unless ARGV[0] and ARGV[1]
abort('Input file does not exist') unless File.exists? ARGV[0]
Dir.mkdir(ARGV[1]) unless Dir.exists? ARGV[1]

urls = JSON.parse(File.open(ARGV[0]).read)
Downloader.new(ARGV[1], urls).run
