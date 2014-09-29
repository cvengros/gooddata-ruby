# encoding: UTF-8

require 'gooddata/models/domain'

describe GoodData::Domain do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  after(:each) do
    @client.disconnect
  end

  describe '#add_user' do
    it 'Should add user' do
      args = {
        :domain => ConnectionHelper::DEFAULT_DOMAIN,
        :login => "gemtest#{rand(1e6)}@gooddata.com",
        :password => CryptoHelper.generate_password,
      }

      user = @domain.add_user(args, client: @client)
      expect(user).to be_an_instance_of(GoodData::Profile)
      user.delete
    end
  end

  describe '#users' do
    it 'Should list users' do
      users = @domain.users
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Accepts pagination options - limit' do
      users = @domain.users(limit: 1)
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Accepts pagination options - offset' do
      users = @domain.users(offset: 1)
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end
  end

  describe '#create_users' do
    it 'Creates new users from list' do
      list = (0...10).to_a.map { |i| ProjectHelper.create_random_user }
      res = @domain.create_users(list)

      # no errors
      expect(res.select { |x| x[:type] == :user_added_to_domain }.count).to eq res.count
      expect(@domain.members?(list.map(&:login)).all?).to be_true

      res.map { |r| r[:user] }.each do |r|
        expect(r).to be_an_instance_of(GoodData::Profile)
        r.delete
      end
    end

    it 'Update a user' do
      user = @domain.users.sample
      login = user.login
      name = user.first_name

      user.first_name = name.reverse
      @domain.create_users([user])
      changed_user = @domain.member(login)
      expect(changed_user.first_name).to eq name.reverse

      user.first_name = name
      @domain.create_users([user])
      reverted_user = @domain.member(login)
      expect(reverted_user.first_name).to eq name
    end

    it 'Fails with an exception if you try to create a user that is in a different domain' do
      user = ProjectHelper.create_random_user
      user.login = 'svarovsky@gooddata.com'
      expect do
        @domain.create_user(user)
      end.to raise_exception(GoodData::UserInDifferentDomainError)
    end

    it 'updates properties of a profile' do
      user = @domain.users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }.sample

      old_email = user.email
      user.email = 'john.doe@gooddata.com'
      @domain.update_user(user)
      expect(@domain.member(user.login).email).to eq 'john.doe@gooddata.com'
      user.email = old_email
      @domain.update_user(user)
      expect(@domain.member(user.login).email).to eq old_email
    end
  end
end
