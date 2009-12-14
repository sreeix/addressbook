require 'rubygems'
require 'json'
require 'rest_client'
require 'cgi'
class User
  def initialize(user)
    @user=user
  end
  def id
    @id
  end
  def name
    @user[:cn]
  end
  def email
    @user[:userprincipalname].first
  end
  def merge!(existing)
    @id =existing["_id"]
    @rev=existing["_rev"]
    self
  end
  def newer?(updated_at)
    puts "#{ @user.whenchanged.first} and #{updated_at}"
    DateTime.parse(@user.whenchanged.first) > DateTime.parse(updated_at)
  end

  def to_json
    representation.to_json
  end
  # refactor this shit
  def representation
    rep={
      :id=>@user[:userprincipalname].first,
      :username=>@user[:uid].first,
      :logon_count=> @user[:logoncount].first,
      :displayname=> @user.cn.first,
      :title=> @user[:title].first,
      :other_emails=> @user[:othermailbox],
      :created_at=> DateTime.parse(@user.whencreated.first),
      :updated_at=> DateTime.parse(@user.whenchanged.first),
      :email=> email,
      :address=>{ :street=>@user[:streetaddress].first,:state=>@user[:st].first,:country=>@user[:co].first, :city=>@user[:l].first, :postcode=> @user[:postalcode].first},
      :phones=>{:home=>@user[:homephone].first,:mobile=> @user[:othermobile].first },
      :im=> im
    }
    rep.merge!({ "_id" => @id, "_rev"=>@rev}) unless @id.nil?
    rep
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
    @bad=[]
    @good=[]
  end

  def export(users)
    users.each{ |user| post(User.new(user))}
    puts "Good user #{@good.size}"
    puts "Bad Users #{@bad.size}"
  end

  def sync(users)
    users.each { |user| update(User.new(user))}
    puts "Good user #{@good.size}"
    puts "Bad Users #{@bad.size}"

  end

  def update(user)
    match=JSON::parse(RestClient.get("#{@url}/_design/address_book/_view/by_email?key="+CGI::escape('"'+user.email+'"')))["rows"].first
    puts match["value"].inspect
    put(user.merge!(match["value"])) if (!match.nil? and user.newer? match["value"]["updated_at"])
  end

  # duplicated
  def put(user)
    begin
      RestClient.put("#{ @url}/#{user.id}", user.to_json)
      @good << user
    rescue Exception=>ex
      @bad << user
      $stderr.puts ex
      $stderr.puts "Exception happened Ignoring #{user.name}"
    end

  end
  def post(user)
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


