require 'rubygems'
require 'json'
require 'rest_client'

class User
  def initialize(user)
    @user=user
  end
  def id
    @user[:userprincipalname].first
  end
  def name
    @user[:cn]
  end

  def to_json
    {
      :id=>@user[:uidnumber].first,
      :username=>@user[:uid].first,
      :logon_count=> @user[:logoncount].first,
      :displayname=> @user.cn.first,
      :title=> @user[:title].first,
      :other_emails=> @user[:othermailbox],
      :created_at=>DateTime.parse(@user.whencreated.first),
      :home_office=>@user[:physicaldeliveryofficename].first,
      :email=>@user.userprincipalname.first,
      :address=>{ :street=>@user[:streetaddress].first,:state=>@user[:st].first,:country=>@user[:co].first, :city=>@user[:l].first, :postcode=> @user[:postalcode].first},
      :phones=>{:home=>@user[:homephone].first,:mobile=> @user[:othermobile].first },
      :im=> im
    }.to_json

  end
  def im
    begin
      @user[:info].first.nil? ? "": JSON::parse(@user[:info].first)
    rescue Exception=> e
      $stderr.puts "problen with parsing im info"
      $stderr.puts e
      ""
    end
  end
end

class Couch
  def initialize(opts={ })
    host=opts["host"] || "http://127.0.0.1.5984"
    database=opts["database"] || "addressbook"
    @url= "#{host}/#{database}"
  end

  def export(users)
    @bad=[]
    @good=[]
    users.each{ |user| create(User.new(user))}
    puts "Good user #{@good.size}"
    puts "Bad Users #{@bad.size}"
  end

  def create(user)
    begin
      RestClient.post(@url, user.to_json)
      @good << user
    rescue Exception=>ex
      @bad << user
      $stderr.puts ex
      $stderr.puts "Exception happened Ignoring #{user.name}"
    end

  end
end


