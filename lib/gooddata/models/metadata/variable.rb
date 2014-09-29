# encoding: UTF-8

require_relative '../metadata'

require_relative 'metadata'

module GoodData
  class Variable < MdObject
    root_key :prompt

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('prompts', Variable, options)
      end

      def create(data, options = { :client => GoodData.connection, :project => GoodData.project })
        title = data[:title]
        project = options[:project]
        c = client(options)
        attribute = project.attributes(data[:attribute])

        payload = {"prompt"=>
             {"content"=>
               {"attribute"=> attribute.uri,
                "type"=>"filter"},
              "meta"=>
               {"tags"=>"",
                "deprecated"=>"0",
                "summary"=>"",
                "title" => title,
                "category"=>"prompt"
              }
            }
          }
        c.create(self, payload, project: project)
      end
    end

    def user_values
      payload = {
          variablesSearch: {
              variables: [
                  uri
              ],
              context: [

              ]
          }
      }
      client.post("/gdc/md/#{project.pid}/variables/search", payload)['variables'].map { |f| client.create(GoodData::VariableUserFilter, f, project: project) }
    end

    def delete
      user_values.pmap &:delete
      super
    end

  end
end
