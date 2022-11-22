desc "Copy cribbage game files from ruby-cribbage"

task :copy_ruby_cribbage do
  if not Dir.exist? './lib/ruby-cribbage' 
    Dir.mkdir('./lib/ruby-cribbage')
  end
  if not Dir.exist? './lib/ruby-cribbage/cribbage_game' 
    Dir.mkdir('./lib/ruby-cribbage/cribbage_game')
  end

  FileUtils.copy('../ruby-cribbage/lib/cribbage_game.rb', './lib/ruby-cribbage')

  Dir.chdir('../ruby-cribbage/lib/cribbage_game')
  files = Dir.glob('*.rb')

  files.each do |file|
    puts "copying #{file}..."  
    FileUtils.copy(file, '../../../rails-cribbage/lib/ruby-cribbage/cribbage_game/')
  end
end