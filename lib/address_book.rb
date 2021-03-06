require 'rubygems'
require 'net/ldap'

class AddressBook
  def initialize(options={})
    @host=options["host"]
    @search_base=options["search_base"]
    @port=options["port"] || 389
    @user=options["user"]
    @password=options["password"]
    @filter=options["filter"]
  end
  def users
    @users=@users|| load_users_from_ldap
  end

  def load_users_from_ldap
    ldap = Net::LDAP.new(:host => @host, :port => @port)
    ldap.auth @user, @password
    ldap.bind
    filter = Net::LDAP::Filter.eq( "cn", @filter.nil? ? "*":@filter )
    ldap.search(:base=>@search_base, :return_result=>true,:filter=>filter).find_all{|item| item.objectclass == ["top", "person", "organizationalPerson", "user"]}
  end

  def to_s
    "#{@host }:#{@port}, #{@user}:********"
  end
end



