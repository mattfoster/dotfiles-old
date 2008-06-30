#!/usr/bin/env ruby
# from http://errtheblog.com/posts/89-huba-huba

# require 'fileutils'
# include FileUtils

def link(file, target)
  # If the destination already exists. Tell us and move it.
  if File.exists?(target)
    $stderr.puts "Target exists. Moving to #{target}.old"
    mv(target, "#{target}.old")
  end
  
  ln_s(File.expand_path(file), target)
end

desc "link system specific files, and dotfiles."
task :link_files => [ :link_system_specifics, :link_dotfiles ] do
  puts "All dotiles linked."  
end

desc "link dotfiles and dirs into home directory"
task :link_dotfiles do
  Dir['*'].each do |file|
    next if file =~ /install/
    target = File.join(ENV['HOME'], ".#{file}")  
    next if File.exists?(target) and File.symlink?(target)  
    link(file, target)
  end
  
end

desc "link system specific files in specified directories"
task :link_system_specifics do 
  hostname = %x{hostname}.split('.')[0]
  puts "Linking system specific files using hostname: #{hostname}"
  Dir['ssh/*'].each do |file|
    next unless file =~ /\.#{hostname}$/
    dir = File.dirname(file)
    target = File.join(dir, File.basename(file, ".#{hostname}"))
    next if File.exists?(target) and File.symlink?(target)  
    link(file, target)
  end
end

desc "install git post commit hook"
task :install_git_hook do
  # git push on commit -- probably only needs to be done onec.. nevermind.
  `echo 'git push' > .git/hooks/post-commit`
  `chmod 755 .git/hooks/post-commit`  
end

task :default => [:link_files, :install_git_hook]