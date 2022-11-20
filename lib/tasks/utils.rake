desc "Copy cribbage game files from ruby-cribbage"

task :copy_ruby_cribbage do
  if not Dir.exist? './app/ruby-cribbage' 
    Dir.mkdir('./app/ruby-cribbage')
  end

  Dir.chdir('../ruby-cribbage')
  files = Dir.glob('*.rb')

  files.each do |file|
    puts "copying #{file}..."  
    FileUtils.copy(file, '../rails-cribbage/app/ruby-cribbage/')
  end
end