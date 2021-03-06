# encoding: UTF-8

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class Report < GoodData::MdObject
    root_key :report

    class << self
      def [](id)
        if id == :all
          uri = GoodData.project.md['query'] + '/reports/'
          GoodData.get(uri)['query']['entries']
        else
          super
        end
      end

      def create(options={})
        title = options[:title]
        summary = options[:summary] || ''
        rd = options[:rd] || ReportDefinition.create(:top => options[:top], :left => options[:left])
        rd.save

        report = {
                   'report' => {
                     'content' => {
                       'domains' => [],
                       'definitions' => [rd.uri]
                     },
                     'meta' => {
                       'tags' => '',
                       'deprecated' => '0',
                       'summary' => summary,
                       'title' => title
                     }
                   }
                 }
        # TODO write test for report definitions with explicit identifiers
        report['report']['meta']['identifier'] = options[:identifier] if options[:identifier]
        Report.new report
      end
    end

    def results
      content['results']
    end

    def definitions
      content['definitions']
    end

    def get_latest_report_definition_uri
      definitions.last
    end

    def get_latest_report_definition
      GoodData::MdObject[get_latest_report_definition_uri]
    end

    def remove_definition(definition)
      def_uri = if is_a?(GoodData::ReportDefinition)
        definition.uri
      else
        definition
      end
      content["definitions"] = definitions.reject { |x| x == def_uri }
      self
    end

    # TODO: Cover with test. You would probably need something that will be able to create a report easily from a definition
    def remove_definition_but_latest
      to_remove = definitions - [get_latest_report_definition_uri]
      to_remove.each do |uri|
        remove_definition(uri)
      end
      self
    end

    def purge_report_of_unused_definitions!
      full_list = self.definitions
      self.remove_definition_but_latest
      purged_list = self.definitions
      to_remove = full_list - purged_list
      self.save
      to_remove.each { |uri| GoodData.delete(uri) }
      self
    end

    def execute
      result = GoodData.post '/gdc/xtab2/executor3', {'report_req' => {'report' => uri}}
      data_result_uri = result['execResult']['dataResult']
      result = GoodData.get data_result_uri
      while result['taskState'] && result['taskState']['status'] == 'WAIT' do
        sleep 10
        result = GoodData.get data_result_uri
      end
      ReportDataResult.new(GoodData.get data_result_uri)
    end

    def exportable?
      true
    end

    def export(format)
      result = GoodData.post('/gdc/xtab2/executor3', {'report_req' => {'report' => uri}})
      result1 = GoodData.post('/gdc/exporter/executor', {:result_req => {:format => format, :result => result}})
      png = GoodData.get(result1['uri'], :process => false)
      while (png.code == 202) do
        sleep(1)
        png = GoodData.get(result1['uri'], :process => false)
      end
      png
    end
  end
end
