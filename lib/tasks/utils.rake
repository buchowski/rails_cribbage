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

desc "create a partial view for each card in the cards svg spritesheet"
task :create_card_svgs do
  width = 360
  height = 539
  x_gap = 30
  y_gap = 30
  card_positions = [
    ["ah", "2h", "3h", "4h", "5h", "6h", "7h", "8h", "9h", "10h", "jh", "qh", "kh"],
    ["ad", "2d", "3d", "4d", "5d", "6d", "7d", "8d", "9d", "10d", "jd", "qd", "kd"],
    ["ac", "2c", "3c", "4c", "5c", "6c", "7c", "8c", "9c", "10c", "jc", "qc", "kc"],
    ["as", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s", "10s", "js", "qs", "ks"],
  ]

  card_dimensions_file = File.open("app/presenters/card_svg_dimensions.rb", "w+")
  preview_cards_file = File.open("app/views/cards/cards_preview.html.erb", "w+")
  preview_cards_file.write("<h1>Preview of generated svg elements</h1>\n")
  card_dimensions = {}

  card_positions.each_with_index do |row, i|
    row.each_with_index do |card, j|
      top = i * height + (i + 1) * y_gap + i
      left = j * width + (j + 1) * x_gap

      dimensions = {
        id: card,
        width: width,
        height: height,
        viewBox: "#{left} #{top} #{width} #{height}"
      }
      card_dimensions[card] = dimensions

      preview_cards_file.write("<%= render partial: 'cards/card_svg', locals: { card: '#{card}' } %>\n")
    end
  end

  card_dimensions_file.write("CardSvgDimensions =\n")
  card_dimensions_file.write(card_dimensions.pretty_inspect)
end

desc "create css classes for each card in the png spritesheet"
task :create_card_classes do
  width = 71
  height = 96
  x_gap = 0
  y_gap = 0
  card_positions = [
    ["as", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s", "10s", "js", "qs", "ks"],
    ["ah", "2h", "3h", "4h", "5h", "6h", "7h", "8h", "9h", "10h", "jh", "qh", "kh"],
    ["ac", "2c", "3c", "4c", "5c", "6c", "7c", "8c", "9c", "10c", "jc", "qc", "kc"],
    ["ad", "2d", "3d", "4d", "5d", "6d", "7d", "8d", "9d", "10d", "jd", "qd", "kd"],
    ["x_hatch_1", "x_hatch_2", "fish_1", "fish_2", "vine_1", "vine_2", "robot_1", "robot_2", "robot_3", "rose", "green_circle", "red_x", "x_hatch_green"],
    ["shell", "castle_1", "castle_2", "beach_1", "beach_2", "beach_3", "sleeve_1", "sleeve_2", "sleeve_3"]
  ]

  sass_file = File.open("app/assets/stylesheets/cards.scss", "w+")
  preview_cards_file = File.open("app/views/cards/cards_png_preview.html.erb", "w+")
  preview_cards_file.write("<h1>Preview of generated PNG elements</h1>\n")

  card_positions.each_with_index do |row, i|
    preview_cards_file.write("<div class='row'>\n")

    row.each_with_index do |card, j|
      top = i * height + (i + 1) * y_gap + i
      left = j * width + (j + 1) * x_gap

      sass_file.write(".card_#{card} {\n\tbackground-position: -#{left}px -#{top}px;\n}\n")
      preview_cards_file.write("<div class='png_card card_#{card}'></div>\n")
    end

    preview_cards_file.write("</div>\n")
  end
end
