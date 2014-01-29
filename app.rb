$:.unshift 'lib'
require 'sinatra'
require 'lc_callnumber'
require 'sequel'
require 'haml'
require 'sass'


class LCDisplay
  attr_accessor :lcc
  def initialize(lcc)
    @lcc = lcc
  end
  
  def each
    display_data.each do |a|
      yield a[0], a[1]
    end
  end
  
  def display_data
    [
      ['Letter(s)', @lcc.letters],
      ['Digit(s)', @lcc.digits.to_s],
      ['Doon1', @lcc.doon1.to_s],
      ['FirstCutter', @lcc.firstcutter.to_s],
      ['Doon2', @lcc.doon2.to_s],
      ['Other cutters', @lcc.extra_cutters.map(&:to_s).join(",")],
      ['Pub Year', @lcc.year.to_s],
      ['Rest', @lcc.rest]
    ]
  end
end
    

class LCParser < Sinatra::Base
  
  DB = Sequel.connect(ENV['DATABASE_URL'])
  TC = DB[:lcc_testcases]
  
  def db_insert(params)
    components = params[:correct_value]
    TC.insert(
      :original_string => params[:original_string],
      :letters => components[0],
      :digits => components[1],
      :doon1 => components[2],
      :firstcutter => components[3],
      :doon2 => components[4],
      :extra_cutters => components[5],
      :year => components[6],
      :rest => components[7]
     )
   end




    
  
  set :haml, :layout=>:layout
  get '/' do
    haml :index
  end
  
  post '/' do
    lccs = params[:lccs].split(/\s*\n\s*/).take(10)
    results = lccs.each_with_object({}) {|l, h| h[l] = LCDisplay.new(LCCallNumber.parse(l))}
    haml :results, :locals=>{:parsed => results }
  end
  
  post '/correct' do
    db_insert(params)
    'success'
  end
  
end