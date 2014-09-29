module GoodData

require_relative 'user_filter'

  class MandatoryUserFilter < UserFilter
    class << self
      def [](id, options = { client: GoodData.connection, project: GoodData.project })
        if id == :all
          all(options)
        else
          super
        end
      end

      def all(options = { client: GoodData.connection, project: GoodData.project })
        c = client(options)
        project = options[:project]
        vars = c.get(project.md['query'] + '/userfilters/')['query']['entries']
        count = 10000
        offset = 0
        user_lookup = {}
        loop do
          result = c.get("/gdc/md/#{project.pid}/userfilters?count=1000&offset=#{offset}")
          result["userFilters"]["items"].each do |item|
            item["userFilters"].each do |f|
              user_lookup[f] = item["user"]
            end
          end
          break if result["userFilters"]["length"] < offset
          offset += count
        end
        vars.map do |a|
          uri = a['link']
          data = c.get(uri)
          c.create(GoodData::MandatoryUserFilter, 
            {
              "expression" => data['userFilter']['content']['expression'],
              "related" => user_lookup[a['link']],
              "level" => :user,
              "type"  => :filter,
              "uri"   => a['link']
            }, project: project)
        end
      end
    end

    # Creates or updates the mandatory user filter on the server
    #
    # @return [GoodData::MandatoryUserFilter]
    def save
      data = {
        "userFilter" => {
        "content" => {
          "expression" => expression
          },
          "meta" => {
            "category" => "userFilter",
            "title" => related_uri
            }
          }
      }
      res = client.post(project.md['obj'], data)
      @json['uri'] = res['uri']
    end    
  end
end
