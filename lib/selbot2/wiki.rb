module Selbot2
  class Wiki
    include Cinch::Plugin

    HELPS << [":wiki", "search the wiki"]

    match /wiki ((?:\w*\s?){0,3})[\\|$]?/

    def execute(message, query)
      query = query.strip.gsub(' ', '-')
      replies = replies_for("pagename:#{query}")

      if replies.empty?
        google_fallback(message, query)
      end

      replies.each_with_index do |resp, idx|
        message.reply "#{idx + 1}: #{resp}"
      end
    end

    def google_fallback(message, query)
      query += " site:github.com/seleniumhq/selenium/wiki"
      resp   = JSON.parse(RestClient.get("https://www.googleapis.com/customsearch/v1?cx=007816448168391566202%3Apybhzvkvbrq&key=#{ENV['GOOGLE_API_KEY']}&num=1&q=#{URI.escape query}"))
      result = resp['items']

      if result.nil?
        message.reply "No results."
      else
        item = result.first
        message.reply "#{item['title']}: #{item['link']}"
      end
    rescue => e
      message.reply e.message
    end

    def escaper
      @escaper ||= URI::Parser.new
    end

    def replies_for(query)
      resp = RestClient.get "#{Selbot2::REPO}/wiki"
      doc = Nokogiri.HTML(resp.downcase)

      rows = doc.css("#wiki-content a[href*='#{query.downcase}']")
      rows[0..2].map { |d| Page.new(d).url }.compact
    end

    class Page
      def initialize(doc)
        @doc = doc
      end

      def name
        @doc.text.strip
      end

      def url
        path = @doc['href']

        "https://github.com#{path}"
      end

    end # Page
  end # Wiki
end # Selbot2
