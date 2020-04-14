puts "ruby csv.rb"
standard = system("ruby csv.rb")
if standard
    puts "ruby ../../tools/se_open_data/rubyfiles/generate.rb"
    generate = system("ruby ../../tools/se_open_data/rubyfiles/generate.rb")
    if generate
        puts "ruby ../../tools/se_open_data/rubyfiles/deploy.rb"
        deploy = system("ruby ../../tools/se_open_data/rubyfiles/deploy.rb")
        if deploy

            puts "ruby ../../tools/se_open_data/rubyfiles/create_w3id.rb"
            system("ruby ../../tools/se_open_data/rubyfiles/create_w3id.rb")

            puts "ruby ../../tools/se_open_data/rubyfiles/triplestore.rb"
            system("ruby ../../tools/se_open_data/rubyfiles/triplestore.rb")
            
        end

    end

end
