# encoding: UTF-8

require_relative 'base_middleware'

module GoodData::Bricks
  class STDOUTLoggingMiddleware < GoodData::Bricks::Middleware
    def call(params)
      logger = Logger.new(STDOUT)
      params[:logger] = logger
      logger.info('Pipeline starting with STDOUT logger')
      returning(@app.call(params)) do
        logger.info('Pipeline ending')
      end
    end
  end
end