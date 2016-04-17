#!/usr/bin/env ruby

begin
  require 'colorize'
  require 'pp'
  require 'slop'
  require 'yaml'

  # Custom modules and classes
  require_relative 'configuration'
rescue LoadError => e
   puts "Couldn't load required Gem: #{e.message.slice!(25..50)}!".red
   exit
end

# Load configuration file
config = Configuration.load
puts config

# Original Manual http://tartarus.org/~simon/putty-snapshots/htmldoc/Chapter3.html#using-cmdline

# Parse the parameters from commandline
# Definition of options
#TODO Copyright informations with link and auto completion
opts = Slop::Options.new
opts.banner = "Usage: puttytocygwinproxy.rb [options] [user@]host"
opts.separator ""
opts.separator "Options:"
opts.bool '-ssh', '--ssh-protocol', 'selects the SSH protocol (default)'
opts.bool '-telnet', '--telnet-protocol', 'selects the Telnet protocol'
opts.bool '-rlogin', '--rlogin-protocol', 'selects the Rlogin protocol'
opts.bool '-raw', '--raw-protocol', 'selects the raw protocol'
opts.string '-serial', '--serial-protocol', 'selects a serial connection'
opts.separator ""
opts.bool '-v', '--verbose', 'Increase verbosity'
opts.on '--help' do
  puts opts
  exit
end

# Parse options
begin
  parser = Slop::Parser.new(opts)
  result = parser.parse(ARGV)
  user_host = result.arguments.join('%')

  user = user_host.slice(/(^[^%]+(?=@))|((?<=%).*(?=@))/)       # Match everything before @. Start at ^ or %
  host = user_host.slice(/(?<=@).*(?=%)|(?<=@)[^%]+$|^[^%@]+$/) # Match everything after @. Stop at $ or %. Or Catch everything (only one string allowed!)

  raise ArgumentError, "Couldn't detect Host. Use '--help' for more information. The following Arguments were received: '#{ARGV.join(' ')}'".red if not host
rescue Slop::UnknownOption => e
  puts "The Option '#{e.flag}' is unkown. Use '--help' for more information.".red
  exit

rescue Slop::MissingArgument => e
  puts "There was no Argument specified for the option '#{e.flags.join(', ')}'. Use '--help' for more information.".red
  exit

end

#puts result[:H] #=> { hostname: "192.168.0.1", port: 80,
#                 #     files: [], verbose: false }
#
#puts opts # prints out help

# Default case: ssh
if user and host
  puts "start ssh session with #{config["cygwin_installation_path"]} #{config["ssh_client"]} #{user}@#{host}" if result[:verbose]
  pid = Process.spawn("#{config["cygwin_installation_path"]} #{config["ssh_client"]} #{user}@#{host}")
  puts "Babun started with pid #{pid}" if result[:verbose]
  if config["detach_childprocesses"]
    Process.detach(pid)
  else
    Process.wait pid
  end
else
  puts "start ssh session with #{config["cygwin_installation_path"]} #{config["ssh_client"]} #{host}" if result[:verbose]
  pid = Process.spawn("#{config["cygwin_installation_path"]} #{config["ssh_client"]} #{host}")
  puts "Babun started with pid #{pid}" if result[:verbose]
  Process.detach(pid)
end
