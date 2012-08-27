#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'nokogiri'
require 'uri'
require 'open-uri'

if __FILE__ == $0
  if ARGV.size != 2
    $stderr.puts "Usage: #{$0} icecast_URL target_dir"
    exit 1
  end
  url, target_dir = ARGV

  base = URI::parse(url + "/")
  status_url = base + "status.xsl"

  loop do
    doc = open(status_url) { |f| Nokogiri::XML.parse(f) }

    doc.css(".newscontent").each do |mount|
      mountpoint = mount.css(".streamheader h3").text.split[-1]
      stream_url = base + mountpoint[1..-1]

      start = DateTime.parse(mount.xpath(
        "//td[contains(text(), 'started')]/../*[@class='streamdata']").text)
      normalized_start = start.strftime("%Y-%m-%d_%H.%M.%S")

      fname = "%s_%s" % [normalized_start, mountpoint.gsub("/", "")]
      fname = File.join(target_dir, fname)

      next if File.exists?(fname)
      puts "Downloading %s to %s" % [stream_url, fname]
      Process.detach(fork {
        exec "wget", "--quiet", stream_url.to_s, "-O", fname
      })
    end

    sleep 5
  end
end
