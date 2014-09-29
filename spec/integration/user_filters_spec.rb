require 'gooddata'

describe "User filters implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    @project = @client.create_project_from_blueprint(@spec, :auth_token => ConnectionHelper::GD_PROJECT_TOKEN)

    GoodData.with_project(@project) do |p|
      @label = GoodData::Attribute.find_first_by_title('Dev', client: @client, project: @project).label_by_name('email')
      
      blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      commits_data = [
        ["lines_changed","committed_on","dev_id","repo_id"],
        [1,"01/01/2014",1,1],
        [3,"01/02/2014",2,2],
        [5,"05/02/2014",3,1]]
      GoodData::Model.upload_data(commits_data, blueprint, 'commits', :client => @client, :project => @project)
      # blueprint.find_dataset('commits').upload(commits_data)

      devs_data = [
        ["dev_id", "email"],
        [1, "tomas@gooddata.com"],
        [2, "petr@gooddata.com"],
        [3, "jirka@gooddata.com"]]
      GoodData::Model.upload_data(devs_data, blueprint, 'devs', :client => @client, :project => @project)
      # blueprint.find_dataset('devs').upload(devs_data)
    end
  end

  after(:all) do
    @project.delete if @project
  end

  after(:each) do
    @project.data_permissions.pmap &:delete
  end

  it "should create a mandatory user filter" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com', 'jirka@gooddata.com']]

    metric = @project.create_metric("SELECT SUM(#\"Lines Changed\")", :title => 'x')
    # [jirka@gooddata.com | petr@gooddata.com | tomas@gooddata.com]
    # [5.0                | 3.0               | 1.0               ]

    metric.execute.should == 9
    @project.add_data_permissions(filters)
    metric.execute.should == 6
    r = @project.compute_report(left: [metric], top: [@label.attribute])
    r.include_column?(['tomas@gooddata.com', 1]).should == true

    r.include_column?(['tomas@gooddata.com', 1]).should == true
    r.include_column?(['jirka@gooddata.com', 5]).should == true
    r.include_column?(['petr@gooddata.com', 3]).should == false
  end

  it "should fail when asked to set a user not in project. No filters should be set up." do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, "tomas@gooddata.com"],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    expect do
      @project.add_data_permissions(filters)
    end.to raise_error
    expect(@project.data_permissions.count).to eq 0
  end

  it "should pass and set users that are in the projects" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(filters)
    expect(@project.data_permissions.count).to eq 1
  end

  it "should pass and set only users that are in the projects if asked" do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, 'tomas@gooddata.com'],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com']
    ]
    @project.add_data_permissions(filters, users_must_exist: false)
    expect(@project.data_permissions.count).to eq 1
  end

  it "should fail when asked to set a value not in the proejct" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'tomas@gooddata.com'],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com']]
    expect do
      @project.add_data_permissions(filters)
    end.to raise_error
    expect(@project.data_permissions.count).to eq 0
  end

  it "should add a filter with nonexistent values when asked" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'jirka@gooddata.com']]
    @project.add_data_permissions(filters, ignore_missing_values: true)

    expect(@project.data_permissions.pmap {|m| m.pretty_expression}).to eq ["[Dev] IN ([jirka@gooddata.com])"]
    expect(@project.data_permissions.count).to eq 1
  end

  it "should be able to add mandatory filter to a user not in the project if domain is provided" do
    domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    u = domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }

    filters = [[u.login, @label.uri, "tomas@gooddata.com"]]
    expect do
      @project.add_data_permissions(filters)
    end.to raise_error
    @project.add_data_permissions(filters, :domain => domain)
    filters = @project.data_permissions
    expect(filters.first.related.login).to eq u.login
    expect(filters.count).to eq 1
  end

  it "should be able to print data permissions in a human readable form" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]]
    @project.add_data_permissions(filters)
    perms = @project.data_permissions
    pretty = perms.pmap {|f| [f.related.login, f.pretty_expression]}
    expect(perms.first.related).to eq @client.user
    expect(pretty).to eq [["svarovsky+gem_tester@gooddata.com", "[Dev] IN ([tomas@gooddata.com])"]]
  end
end
