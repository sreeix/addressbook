require 'rubygems'
require 'json'
require 'rest_client'
class User
  def initialize(user)
    @user=user
  end

  def method_missing
  end
end

class Couch
  def initialize(opts={ })
    host=opts["host"] || "http://127.0.0.1.5984"
    database=opts["database"] || "addressbook"
    @url= "#{host}/#{database}"
  end
  def export(users)
    bad=[]
    good=[]
      users.each do |user|
      begin
        existing=RestClient.get(url+"/#{user[:userprincipalname].first}")
        puts URL+"/#{user[:uid].first}"
        rep=representation(user)
        rep.merge!( "_rev"=> existing["_rev"]) unless existing.nil?
        RestClient.post(url, rep.to_json)
        good << user
      rescue Exception=>e
        bad << user
        $stderr.puts e
        $stderr.puts "Exception happened Ignoring #{user.cn}"
      end
    end
     puts "Successfully completed #{good.size} documents to db"
    puts "Could not save #{bad.size} to the database"
    puts $stderr.puts bad.inspect
  end

  def representation(user)
    {
      :_id=> user[:userprincipalname].first,
      :id=>user[:uidnumber].first,
      :username=>user[:uid].first,
      :logon_count=> user[:logoncount].first,
     :displayname=> user.cn.first,
      :title=> user[:title].first,
  #    :other_emails=> user[:othermailbox],
      :created_at=>DateTime.parse(user.whencreated.first),
  #    :home_office=>user[:physicaldeliveryofficename].first,
      :email=>user.userprincipalname.first,
      :address=>{ :street=>user[:streetaddress].first,:state=>user[:st].first,:country=>user[:co].first, :city=>user[:l].first, :postcode=> user[:postalcode].first},
      :phones=>{:home=>user[:homephone].first,:mobile=> user[:othermobile].first },
      #    :im=> (user[:info].first.nil? ? "": JSON::parse(user[:info].first))
    }
  end

end


