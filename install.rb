#!/usr/bin/env ruby

require 'fileutils'
include FileUtils
# from http://errtheblog.com/posts/89-huba-huba

home = File.expand_path('~')

Dir['*'].each do |file|
  next if file =~ /install/
  target = File.join(home, ".#{file}")
  #`ln -s #{File.expand_path file} #{target}`

  # On install, we probably want to move the old stuff out of the way.
  begin
    ln_s(File.expand_path(file), target)
  rescue Errno::EEXIST
    mv(target, "#{target}.old") 
    ln_s(File.expand_path(file), target)
  end

end

# git push on commit
`echo 'git push' > .git/hooks/post-commit`
`chmod 755 .git/hooks/post-commit`
