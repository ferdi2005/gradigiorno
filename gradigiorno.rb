require 'mediawiki_api'
require 'roo'
require 'httparty'
require 'json'

unless File.exist? "#{__dir__}/.config"
    puts 'Inserisci username:'
    print '> '
    username = gets.chomp
    puts 'Inserisci password:'
    print '> '
    password = gets.chomp
    puts "Attivo? Scrivere y o n. Nel caso in cui la stringa sia differente, verrà interpretata come n"
    print '> '
    active = gets.chomp
    File.open("#{__dir__}/.config", "w") do |file| 
      file.puts usernamem
      file.puts password
      file.puts active
    end
end
userdata = File.open("#{__dir__}/.config", "r").to_a

wikipedia = MediawikiApi::Client.new("https://it.wikipedia.org/w/api.php")
wikipedia.log_in(userdata[0].strip, userdata[1].strip)
active = userdata[2].strip == "y" ? true : false
f = File.open("comuni.csv", "w")
m = File.open("mancanti.csv", "w")
csv = Roo::Spreadsheet.open("tabella.csv")
c = 0
tot = 0
n = 0

# row[4] contiene il nome del comune
# row[2] contiene i gradi giorno.
unless File.exist? "#{__dir__}/lista.txt"
    url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&negcats=Comuni%20d%27Italia%20soppressi&depth=8&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa"
    petscan = HTTParty.get(url, timeout: 1000).to_h["*"][0]["a"]["*"]
    lista = File.open("#{__dir__}/lista.txt", "w")
    lista.write(petscan.to_json)
    lista.close
end
petscan = JSON.parse(File.read("#{__dir__}/lista.txt"))
puts 'Inizio a processare le pagine...'
begin
    csv.each do |row|
        if !row[0].nil? && row[0] != "" && row[0] != "pr"
            tot += 1
            # stringaricerca = 'intitle:"' + row[4].strip + '" comune italiano'
            # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
            if petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_"))} != nil || petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("-", "_"))} != nil ||  petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("_", "-"))} != nil || petscan.find { |e| e["title"].include?(row[4].strip.gsub("è","é").gsub(" ", "_"))} != nil || petscan.find { |e| e["title"].include?(row[4].strip.gsub("é","è").gsub(" ", "_"))} != nil 
                # title = search.data["search"][0]["title"]
                if petscan.select { |e| e["title"].include?(row[4].strip.gsub(" ", "_"))}.count > 1
                    if petscan.find { |e| e["title"] == row[4].strip.gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == row[4].strip.gsub(" ", "_")}["title"]
                    elsif petscan.find { |e| e["title"] == "#{row[4].strip} (Italia)".gsub(" ", "_")} != nil
                        title = petscan.find { |e| e["title"] == "#{row[4].strip} (Italia)".gsub(" ", "_")}["title"]
                    else
                        puts "#{row[4].strip} più opzioni"
                        n += 1
                        next
                    end
                elsif petscan.find { |e| e["title"] == "#{row[4].strip} (Italia)".gsub(" ", "_")} != nil
                    title = petscan.find { |e| e["title"] == "#{row[4].strip} (Italia)".gsub(" ", "_")}["title"]
                elsif petscan.find { |e| e["title"].include?(row[4].strip.gsub("è","é").gsub(" ", "_"))} != nil 
                    title = petscan.find { |e| e["title"].include?(row[4].strip.gsub("è","é").gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[4].strip.gsub("é","è").gsub(" ", "_"))} != nil 
                    title = petscan.find { |e| e["title"].include?(row[4].strip.gsub("é","è").gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("-", "_"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("-", "_"))}["title"]
                elsif petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("_", "-"))} != nil
                    title = petscan.find { |e| e["title"].include?(row[4].strip.gsub(" ", "_").gsub("_", "-"))}["title"]
                end
                wikitext = wikipedia.query prop: :revisions, titles: title, rvprop: :content, rvslots: "*"
                begin
                    text = wikitext.data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]
                    if text.match?(/\|\s*Gradi\sgiorno\s*=\s*(\d+)/i)
                            gradigiorno = row[2]
                            match = text.match(/\|\s*Gradi\sgiorno\s*=\s*(\d+)/i)
                        if match[1] != gradigiorno
                            c += 1
                            f.write("#{title},#{match[1]},#{gradigiorno}\n")
                            if active
                                text.gsub!(/\|\s*Gradi\sgiorno\s*=\s*[\d\,\.]+\n*/i, "|Gradi giorno = #{gradigiorno}\n")
                                wikipedia.edit(title: title, text: text, summary: "Correzione dei gradi giorno (vedi [[Discussioni progetto:Amministrazioni/Comuni italiani#Monitoraggio dei gradi giorno]])", bot: true)
                                puts "Pagina #{title} aggiornata con successo"
                            end
                        end
                    else
                        puts "#{row[4].strip} trovato #{title} e non matchabile (#{row[2]})"
                        m.write("#{title},#{row[2]}\n")
                        n += 1
                        if text.match?(/^\|\s*Gradi\sgiorno\s*=\s*$/im)
                            if active
                                gradigiorno = row[2]
                                text.gsub!(/\|\s*Gradi\sgiorno\s*=\s*\n*/i, "|Gradi giorno = #{gradigiorno}\n")
                                wikipedia.edit(title: title, text: text, summary: "Aggiunta dei gradi giorno (vedi [[Discussioni progetto:Amministrazioni/Comuni italiani#Monitoraggio dei gradi giorno]])", bot: true)
                                puts "Pagina #{title} aggiornata con successo"
                            end
                        end
                    end
                rescue
                    puts "#{row[4].strip} non trovato in ricerca"
                    n += 1
                    next
                end
            else 
                puts "#{row[4].strip} non trovato"
                n += 1
            end
        end
    end
rescue Interrupt => e 
    puts "Salvo..."
    f.close
    m.close
    puts "Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
end
f.close
m.close
puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."