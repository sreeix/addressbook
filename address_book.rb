require 'rubygems'
require 'net/ldap'
require 'couch'
require 'yaml'

class AddressBook
  attr_reader :users
  def initialize(options={})
    @host=options["host"]
    @search_base=options["search_base"]
    @port=options["port"] || 389
    @user=options["user"]
    @password=options["password"]
  end
  def import
    ldap = Net::LDAP.new(:host => @host, :port => @port)
    ldap.auth @user, @password
    ldap.bind
    @users=ldap.search(:base=>@search_base, :return_result=>true)
  end
  def to_s
    "#{@host }:#{@port}, #{@user}:********"
  end
end

addr_book=AddressBook.new(YAML::load(File.read("local.yml"))["development"])
Couch.new.export(addr_book.import.find_all{|item| item.objectclass == ["top", "person", "organizationalPerson", "user"]})

