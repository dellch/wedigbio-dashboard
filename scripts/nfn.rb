require_relative 'cartodb'
require 'json'
require 'open-uri'

begin
  table_name = "wdb"
  values = []
  #time for zooniverse url MM-DD-HH (last hour)
  url_time = Time.now.strftime('%m-%d-') + (Time.now.hour - 1).to_s.rjust(2, "0")
  nfn_url = "ZOONIVERSE HOURLY URL GOES HERE"

  open(nfn_url) do |nfn|
    nfn.each_line do |line|
      obj = JSON.parse(line)
      subject = obj["subjects"].first
      id = obj["_id"]["$oid"]
      project = "Notes from Nature"
      user_id = obj["user_id"] ? obj["user_id"]["$oid"] : ""
      user_ip_address = obj["user_ip"]
      subject_id = subject["id"]["$oid"]
      specimen_url = subject["location"]["standard"]
      specimen_image_url = subject["location"]["standard"]
      transcription_timestamp = obj["updated_at"]["$date"]
      transcribed_country = ""
      transcribed_state = ""
      transcribed_county = ""
      transcribed_species = ""
      obj["annotations"].each do |ann|
        case ann["step"]
          when "State/Province"
            transcribed_state = ann["value"]
          when "Country"
            transcribed_country = ann["value"]
          when "County"
            transcribed_county = ann["value"]
          when "Scientific name"
            transcribed_species = ann["value"]
        end
        if ann.has_key? "group"
          project = "NFN - #{ann["group"]["name"]}"
        end
      end
      values.push("('#{id}','#{project}','#{user_id}','#{user_ip_address}','#{subject_id}','#{specimen_url}','#{specimen_image_url}','#{transcription_timestamp}','#{transcribed_country}','#{transcribed_state}','#{transcribed_county}','#{transcribed_species}', '#{Time.now.to_s}')")
    end
  end
  cartodb = CartoDB.new(table_name)
  cartodb.insert values
  cartodb.georeference
rescue
  #error handling
end