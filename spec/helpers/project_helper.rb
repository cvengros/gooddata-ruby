# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module ProjectHelper
  PROJECT_ID = 'we1vvh4il93r0927r809i3agif50d7iz'
  PROJECT_URL = "/gdc/projects/#{PROJECT_ID}"
  PROJECT_TITLE = 'GoodTravis'
  PROJECT_SUMMARY = 'No summary'

  def self.get_default_project(opts = { :client => GoodData.connection })
    GoodData::Project[PROJECT_ID, opts]
  end

  def self.create_random_user
    num = rand(1e6)
    login = "gemtest#{num}@gooddata.com"

    json = {
      'user' => {
        'content' => {
          'email' => login,
          'login' => login,
          'firstname' => 'the',
          'lastname' => num.to_s,

          # Following lines are ugly hack
          'role' => 'editor',
          'password' => CryptoHelper.generate_password,
          'domain' => ConnectionHelper::DEFAULT_DOMAIN,

          # And following lines are even much more ugly hack
          # 'sso_provider' => '',
          # 'authentication_modes' => ['sso', 'password']
        },
        'meta' => {}
      }
    }
    GoodData::Membership.new(json)
  end
end
