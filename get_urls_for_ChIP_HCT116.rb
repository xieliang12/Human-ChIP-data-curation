require 'open-uri'
require 'nokogiri'
require 'json'

chip_seq_url = "https://www.encodeproject.org/search/?type=Experiment&assay_\
title=ChIP-seq&limit=all&format=json"

chip_seq = open(chip_seq_url) { |f| f.read }
all_experiments = JSON.parse(chip_seq)

hct116_chip = []
targets = []
all_experiments['@graph'].each do |experiment|
  if experiment['biosample_term_name'].include?("HCT116")
    hct116_chip << experiment['accession']
    targets << experiment['target']['label']
  end
end

hct116_chip_target = Hash[hct116_chip.zip(targets)]

class String
  def extract_strings_between(start_marker, stop_marker)
    self.scan(/#{start_marker}(.*?)#{stop_marker}/m)
  end
end

download_urls = []

hct116_chip.each do |symbol|
  url = "https://www.encodeproject.org/experiments/#{symbol}/"
  begin
    doc = Nokogiri::HTML(open(url))
  rescue OpenURI::HTTPError => e
    puts "Can't get access #{url}"
    puts e.message
    puts
    next
  end
  script_data = doc.xpath('//script[@type="application/ld+json"]/text()').to_s
  replacements = [['"', ''], ['{', ''], ['}', ''], [']', ''], 
                  ['[', ''], [':', '']]
  replacements.each { |replacement| script_data.gsub!(replacement[0],
                                                 replacement[1])}
  links = script_data.extract_strings_between("href", ",").uniq
  website = "https://www.encodeproject.org"
  links.each do |link|
    if link.join("").include?("fastq.gz")
      download_urls << (website + link.join(""))
    end
  end
end

  # write all Raw data download URLs of ChIP-seq done on HCT116 cell lines to file
File.open("results/HCT116_ChIP_Raw_Data_URLs.csv", "w") do |f|
  download_urls.uniq.each { |url| f.puts(url) }
end

File.open("results/HCT116_ChIP_Target.csv", "w") do |f|
  hct116_chip_target.each do |key, value|
    f.puts(key+"\t"+value)
  end
end
