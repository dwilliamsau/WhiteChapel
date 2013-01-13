#!/usr/bin/env ruby
require	'rubygems'
require 'sinatra'
require 'haml'
require 'tire'
require 'rex'

configure do
	set :public_folder, Proc.new { File.join(root, "static") }
	set :per_page, 25
end

def check_unique_and_store(password,hash)
	check = Tire.search 'whitechapel-hashes' do |search|
		search.query { |query| query.string "password:#{password} hash:#{hash}"}
	end
	if check.results.total > 0 then
		"Not Unique, returning"
	else
		"Need to store it as new"
	end
end

helpers do
	Tire.configure do
		elasurl = File.open("elastic.conf").first
		url("#{elasurl.chomp}/")
	end

	Tire.index 'connectivitytest' do
		delete
		create
		store :title => 'One',   :tags => ['ruby'],           :published_on => '2011-01-01'
		store :title => 'Two',   :tags => ['ruby', 'python'], :published_on => '2011-01-02'
		delete
	end

	Tire.index 'whitechapel-hashes' do
		# REMOVE THIS DELETE
		delete

		create :mappings => {
			:document => {
			  :properties => {
					:password  => { :type => 'string', :index => 'not_analyzed', :include_in_all => false },
					:hash      => { :type => 'string', :analyzer => 'snowball'  },
					:type     => { :type => 'string'}
				}
			}
		}
		document = [
			{:password => 'hello world', :hash => '5eb63bbbe01eeed093cb22bb8f5acdc3', :hashtype => 'md5', :type => 'document'},
			{:password => 'password', :hash => '5f4dcc3b5aa765d61d8327deb882cf99', :hashtype => 'md5', :type => 'document'}
		]

		import document
	end
end

get '/' do
	# puts @s.to_curl

	erb :index
end

get '/search/pass' do
	q = params[:q].to_s !~ /\S/ ? '*' : params[:q].to_s
	f = params[:p].to_i*settings.per_page

	@s = Tire.search( 'whitechapel-hashes' ) do |search|
		search.query { |query| query.string "password:\"#{q}\"" }
		search.size settings.per_page
		search.from f
	end

	erb :search
end

get '/search/hash' do
	h = params[:h].to_s !~ /\S/ ? '*' : params[:h].to_s
	f = params[:p].to_i*settings.per_page

	@s = Tire.search( 'whitechapel-hashes' ) do |search|
		search.query { |query| query.string "hash:#{h}" }
		search.size settings.per_page
		search.from f
	end

	erb :search
end

# Handle GET-request (Show the upload form)
get "/upload" do
  erb :upload
end

post "/upload/dictionary" do
  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
	f.write(params['myfile'][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end

# Handle POST-request (Receive and save the uploaded file)
post "/upload/pwdump" do
  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
	f.write(params['myfile'][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end

post "/upload/shadowfile" do
  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
	f.write(params['myfile'][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end







# john ./johnfile.txt --show=LEFT --format=NT