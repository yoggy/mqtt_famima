#!/usr/bin/ruby
#  -*- encoding: utf-8 -*-
#
# mqtt_famima.rb - simple example of how to subscribe topic using MQTT library
#
#   $ sudo gem install mqtt
#   $ sudo gem install pit
#
require 'rubygems'
require 'mqtt'
require 'json'
require 'time'
require 'pit'

config = Pit.get("mqtt_famima", :require => {
	"remote_host" => "mqtt.example.com",
	"remote_port" => 1883,
	"username" => "username",
	"password" => "password",
	"topic" => "topic",
})
conn_opts = {
	remote_host: config["remote_host"],
	remote_port: config["remote_port"].to_i,
	username: config["username"],
	password: config["password"],
}

$last_open_time = Time.now.to_i

def last_open_diff
	Time.now.to_i - $last_open_time
end

def on_open_door
	return if last_open_diff < 10

	cmd = "aplay famima.wav"
	puts "exec : #{cmd}"
	system(cmd)

	$last_open_time = Time.now.to_i
end

old_door = 0

Dir.chdir(File.dirname($0))

loop do
	begin
		MQTT::Client.connect(conn_opts) do |c|
			c.get(config['topic']) do |t, msg|
				begin
					json = JSON.parse(msg)
					puts Time.now.iso8601 + " : " + json.to_s
					now_door = json["door"]
					if now_door != old_door
						if now_door.to_i == 1
							on_open_door
						end
					end
					old_door = now_door
				rescue Exception => e
					puts e
				end
			end
		end
	rescue Exception => e
		puts e
	end
	sleep 5
end

