require 'date'
require 'net/http'
require 'json'

class MapValidator
  module ValidatorFunctions
    def formatSource(meta)
      "#{meta[:col]}:#{meta[:row]}"
    end

    # @param [Notifications] notifications
    # @param [Object] meta
    # @param [Object] value
    # @return [Object]
    def is_not_nil(notifications, meta, value)
      if value.nil?
        notifications.add_notification :ERROR,
                                       'Value was missing.',
                                       formatSource(meta)
      end
    end

    def is_not_empty(notifications, meta, value)
      if value.nil? || value.length.zero?
        notifications.add_notification :ERROR,
                                       'Value was missing or empty.',
                                       formatSource(meta)
      end
    end

    def is_valid_date(notifications, meta, value)
      if !meta[:mandatory] && value.nil?
        return
      end
      begin
        Date.parse(value)
      rescue ArgumentError, TypeError
        notifications.add_notification :ERROR,
                                       'Value was not a valid timestamp.',
                                       formatSource(meta)
      end
    end

    def is_integer(notifications, meta, value)
      if !meta[:mandatory] && value.nil?
        return
      end
      convertedInt = nil
      begin
        convertedInt = Integer(value)
      rescue
        notifications.add_notification :ERROR, 'Value was not a whole number.', formatSource(meta)
      end

      if !meta[:minValue].nil? && convertedInt < meta[:minValue]
        notifications.add_notification :ERROR, 'Value was lower than specified minimum value.', formatSource(meta)
      end
    end

    def is_in_vocab(notifications, meta, value)
      raise ArgumentError, 'Vocabulary parameter was not specified in `meta`.' unless meta[:vocabulary]

      # Optional values don't need to be parsed
      if !meta[:mandatory] && value.nil?
        return
      elsif value.nil?
        notifications.add_notification :ERROR, 'Vocabulary value was empty.', formatSource(meta)
      end
      valueArray = []
      valueArray = value.split(',') if value.is_a? String
      valueArray.each do |split_value|
        split_value = split_value.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
        unless meta[:vocabulary].include? split_value
          notifications.add_notification :ERROR, "Value `#{split_value}` was not found in the list of vocabulary terms.", formatSource(meta)
        end
      end
    end

    def is_boolean(notifications, meta, value)
      true_value = meta[:true_value]
      false_value = meta[:false_value]
      raise ArgumentError, 'Boolean true/false arguments were not supplied.' if true_value.nil? || false_value.nil?
      if !meta[:mandatory] && value.nil?
        return
      end
      unless [true_value, false_value].include? value
        notifications.add_notification :ERROR, "Value `#{value}` was neither  `#{true_value}`, nor `#{false_value}`", formatSource(meta)
      end
    end

    def row_id_exists(notifications, meta, value)
      # Optional values don't need to be parsed
      if !meta[:mandatory] && value.nil?
        return
      end
      if meta[:mandatory] && value.nil?
        notifications.add_notification :ERROR, 'ID field was marked as mandatory, but value was empty.', formatSource(meta)
      end

      solr_query = "primary_type:#{meta[:type]} AND #{meta[:id_field]}:#{value}"
      solr_url = "#{@app_config[:solr_url]}/select"
      uri = URI(solr_url)
      uri.query = URI.encode_www_form(q: solr_query, qt: 'json')
      request = Net::HTTP::Get.new(uri)
      Net::HTTP.start(uri.host, uri.port) do |http|
        response = http.request(request)
        unless response.code == '200'
          notifications.add_notification :ERROR, "When checking the database, recieved code: #{response.code} with message: #{JSON.parse(response.body)['response']}"
          return
        end
        docs = JSON.parse(response.body).fetch('response').fetch('docs').map {|hit| Hash[meta[:id_field], hit.fetch(meta[:id_field])]}
        if docs.empty? || docs[0][meta[:id_field]] != value
          notifications.add_notification :ERROR, "No match found for field `#{meta[:id_field]}`: #{value}"
        end
      end
    end
  end
end
