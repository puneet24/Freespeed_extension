# Test code for testing freespeed in which watch is applied to individual file.
#	These file will fire events as soon as file is modified and saved .
#	The main aim is to check watch should not fail if file is deleted and then recreated.

require 'fileutils'
require '/home/puneet/freespeed.rb'

# Testing Freespeed API #

FILES = %w(1.txt 2.txt 3.txt)

FileUtils.touch(FILES)

sleep 5

paths = FILES
a = Freespeed::EventedMonitorChecker.new(paths) do 
		puts "Rails is awesome."
	end
count = 0
while count < 5
	if a.execute_if_updated?
		count += 1
		puts count
	end
end
