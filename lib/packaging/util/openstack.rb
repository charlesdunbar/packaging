# Utility methods for dealing with shipping data to Swift

require 'fog/openstack'

module Pkg::Util::Openstack
  class << self

    # Connect to swift with credentials, return the connection object
    def connect(auth_url, username, key)
      os = Fog::Storage::OpenStack.new({:openstack_username  => username, :openstack_api_key => key, :openstack_auth_url  => auth_url})
      # TODO - rescue here for failures
      os
    end

    # Create a container if needed, otherwise do nothing
    # Will ideally have one container for one repo/project
    def create_container(connection, project)
      unless connection.directories.get(project)
        puts "Creating #{project} container"
        # Extra headers to enable static web browsing
        os.put_container(project, :headers => {'x-container-meta-web-listings' => true, 'x-container-read' => '.r:*,.rlistings'})
      end
    end

    # Send all data in a directory up to swift
    # connection - the connect object
    # dir - the dir to ship
    # project - project name
    # prepend - what to prepend each file with, ideally the git ref and any parent dirs
    def ship_dir(connection, dir, project, prepend)
      container = connection.directories.get(project)

      # I only want files, but they can have directory names attached to them.
      # I don't want just directory names
      to_ship = Dir.glob("#{dir}/**/*").reject do |file|
        File.directory?(file)
      end

      # Ideally at some point we'll turn all of the meta data in the yaml config
      # into metadata for the swift objects, but that will require removing the nils
      # and converting the arrays into individual values

      # For now, we just add the "test" metadata, with the value of wow.

      to_ship.each do |file|
        puts "Creating #{prepend}/#{file.split("#{dir}/")[1]}"
        container.files.create(:key => "#{prepend}/#{file.split("#{dir}/")[1]}", :body => File.open(file), :headers => {'x-object-meta-test'=> 'wow'})
      end
    end
  end
end

