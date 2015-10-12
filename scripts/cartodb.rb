require 'json'
require 'net/http'
require 'open-uri'
require 'csv'

class CartoDB



  def initialize(table)
    @table = table
    ###This is an old API KEY, update with new key for production###
    @api_key = "fe61d32b4352583a0abdf3e0fab25bf8cb7c7272"
    @api_url = "http://nfn.cartodb.com/api/v2/sql"
  end


  def insert(values)
    ##################
    #Order of values must be: [
    #     transcription_id,
    #     transcription_center,
    #     project,
    #     user_id,
    #     user_ip_address,
    #     subject_id,
    #     specimen_url,
    #     specimen_image_url,
    #     transcription_timestamp,
    #     transcribed_country,
    #     transcribed_state,
    #     transcribed_county,
    #     transcribed_species,
    #     Time.now.to_s
    # ]
    ######################
    begin_sql = "INSERT INTO #{@table} (transcription_id, transcription_center, project_name, user_id, user_ip, subject_id, specimen_url, specimen_image_url, transcription_timestamp, transcribed_country, transcribed_state, transcribed_county, transcribed_species, upload_timestamp)"
    values.map!{ |row| "('" + row.map{ |r| r.gsub("'","") }.join("','") + "')" }
    params = {
        "q"       => begin_sql + " values " + values.join(","),
        "api_key" => @api_key }
    response = Net::HTTP.post_form(URI.parse(@api_url), params)
    return response
  end


  def georeference
    params = {
        "kind"          => "ipaddress",
        "column_name"   => "user_ip",
        "formatter"     => "",
        "table_name"    => @table,
        "state"         => "",
        "geometry_type" => "point",
        "api_key"       => @api_key }
    api_url = "https://nfn.cartodb.com/api/v1/geocodings"
    response = Net::HTTP.post_form(URI.parse(api_url), params)
    return response
  end


  def get_totals
    start = Time.new(2015,10,8,23,50,0,"-04:00")
    csv = "wedigbio.csv"
    query = "SELECT project_name, Count(project_name) FROM #{@table} GROUP BY project_name;"
    json = self.select(query)
    if json["rows"] && json["rows"].length > 0
      hours_elapsed = (Time.now - start)/60/60
      CSV.open(csv, 'ab') do |file|
        json["rows"].each{ |row| file << [ row["project_name"], row["count"], hours_elapsed.round ] }
      end
    end
  end

  def get_last_timestamp transcription_center
    query = "SELECT transcription_timestamp FROM #{@table} WHERE transcription_center = #{transcription_center} ORDER BY transcription_timestamp desc limit 1"
    json = self.select(query)
    if json["rows"] && json["rows"].length > 0
      return Time.parse(json["rows"][0]["transcription_timestamp"])
    else
      return Time.new("")
    end
  end

  def select query
    params = { "q" => query,
               "api_key" => @api_key }
    uri = URI.parse(@api_url + "?" + URI.encode_www_form(params))
    response = Net::HTTP.get_response(uri)
    return JSON.parse(response.body)
  end

end