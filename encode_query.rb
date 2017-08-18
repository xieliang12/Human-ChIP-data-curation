require 'open-uri'
require 'json'
require 'csv'
require 'date'

query_term1 = "ChIP-seq"
query_term2 = "August 2012"
month, year = query_term2.split(" ")
month_index = format('%02d',Date::MONTHNAMES.index(month))
experiment_url = "https://www.encodeproject.org/search/?type=Experiment&month_\
released=#{month}%2C+#{year}&assay_title=#{query_term1}&limit=all&format=json"
biosample_url = "https://www.encodeproject.org/search/?type=biosample&frame=\
object&limit=all&format=json"

experiment = open(experiment_url) { |f| f.read }
experiment_results = JSON.parse(experiment)
biosample = open(biosample_url) { |f| f.read }
biosample_results = JSON.parse(biosample)
output_file = "results/#{query_term1}_#{year}#{month_index}.tab"

experiment_results['@graph'].each do |child|
  arr = []
  accession = child['accession']
  biosample = child['replicates'][0]['library']['biosample']
  organism = biosample['organism']['scientific_name']
  biosample_term_name = child['biosample_term_name']
 
  biosample_type = nil
  biosample_results["@graph"].each do |element|
    if (!element["summary"].nil? && (element["summary"].include? biosample_term_name))
      summary = element["summary"].downcase
      if summary =~ /immortalized cell line/
        biosample_type = "immortalized cell line"
      elsif summary =~ /primary cell/
        biosample_type = "primary cell"
      elsif summary =~ /stem cell/
        biosample_type = "stem cell"
      elsif summary =~ /tissue/
        biosample_type = "tissue"
      elsif summary =~ /in vitro differentiated cells/
        biosample_type = "in vitro differentiated cells"
      end
    end
  end

  num_of_replicates = child['replicates'].length
  protein_target = child['target']['label']
  
  arr << accession << organism << biosample_term_name << biosample_type << \
    protein_target << num_of_replicates
  
  headers = ["Accession", "Organism", "Biosample_Term", "Biosample_Type",
             "Protein_Target", "Num_Of_Replicates"]
  CSV.open(output_file, "a+", {:col_sep => "\t"}) do |csv|
    csv << headers if csv.count.eql? 0 
    csv << arr
  end
end
