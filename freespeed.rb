# Provides Ruby interface for Native system call libraries of linux.

require "rb-inotify"

module Freespeed
  # Freespeed module provides the alternative way of implementing File
  # checker API. This module is currently implemented for linux system
  # and is limited to files only.
  #
  # * +initialize+ which expects two parameters and one block as
  #   described below. 
  #
  # * +updated?+ which returns a boolean if there were updates in
  #   the filesystem or not.
  #
  # * +start_file_notifier+ which just start the file notifier on thread.
  #
  #	* +add_watch+ which expect the file to be watched for file notifications.
  #
  # * +stop_file_notifier+ which just stops the file notifier.
  #
  # * +execute_if_updated+ which just executes the block if it was updated.

  class EventedMonitorChecker
    # It accepts two parameters on initialization. The first is an array
    # of files and the second is an optional hash of directories. The hash must
    # have directories as keys and the value is an array of extensions to be
    # watched under that directory.
    #
    # This method must also receive a block that will be called once a path
    # changes. The array of files and list of directories cannot be changed
    # after FileUpdateChecker has been initialized.
    def initialize(files, dirs={}, &block)
      @files = files.freeze
      @glob = compile_glob(dirs)
      @block = block
      @modified = false
      @thr = nil
      @watched = watched
      #@files_hash = Hash.new
      @last_mtime = Time.now

      @notifier = INotify::Notifier.new

      #Adding watch to the all the files passed as the argument.
      @watched.each do |n_file| 
      	add_watch(n_file)
      end
      
      start_file_notifier
    end
    
    # adding watch to the file passed in arguent
    def add_watch(n_file)
    	@notifier.watch(n_file,:all_events) do |event|
    		puts "event name :- #{event.name} and event flags :- #{event.flags}"
    		check_event_status(event,n_file)
    	end
    end
    
    # This method is for checking event status for file specified in the argument to check the event is considerable or not in order to change @modified.
    def check_event_status(event,n_file)
    	if event.flags.include? :ignored 
    		add_watch(n_file)
    	elsif event.flags.include? :attrib
    		#Comparing modified time of evented file with the last_mtime to check updation in file system.
    		if !File.exists?(n_file) || @last_mtime < File.mtime(event.absolute_name)
    			@modified = true
    			stop_file_notifier
    		end
    	end
    end

    # This method starts taking events by starting the notifier in thread.
    def start_file_notifier
      @modified = false
      stop_file_notifier
      @thr = Thread.new {@notifier.run}
    end

    # This method stops taking the events and stops the thread.
    def stop_file_notifier
      @notifier.stop
      @thr.exit if !@thr.nil?
      @thr = nil
    end

    # This method returns the status, returns 'true' if file system updated else 'false'.
    def updated?
      @modified
    end

    # This method executes the block and return 'true' if file system is updated else false.
    def execute_if_updated?
      if updated?
        @block.call
        @last_mtime = Time.now
        @modified = false
        start_file_notifier
        true
      else
        false
      end
    end

    def compile_glob(hash)
      hash.freeze # Freeze so changes aren't accidentally pushed
      return if hash.empty?

      globs = hash.map do |key, value|
        "#{escape(key)}/**/*#{compile_ext(value)}"
      end
      "{#{globs.join(",")}}"
    end

    def escape(key)
      key.gsub(',','\,')
    end

    def compile_ext(array)
      array = Array(array)
      return if array.empty?
      ".{#{array.join(",")}}"
    end

    def watched
        all = @files.select { |f| File.exist?(f) }
        all.concat(Dir[@glob]) if @glob
        all
    end

  end
end




