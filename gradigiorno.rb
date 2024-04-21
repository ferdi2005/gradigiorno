require 'mediawiki_api'
require 'roo'
require 'httparty'
require 'json'
require 'csv'
require 'progress_bar'

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
      file.puts username
      file.puts password
      file.puts active
    end
end
userdata = File.open("#{__dir__}/.config", "r").to_a

wikipedia = MediawikiApi::Client.new("https://it.wikipedia.org/w/api.php")
wikipedia.log_in(userdata[0].strip, userdata[1].strip)

# Configurazioni ulteriori
active = userdata[2].strip == "y" ? true : false
wikidata_mode = userdata[3].strip == "y" ? true : false

f = File.open("comuni.csv", "w")
m = File.open("mancanti.csv", "w")
d = File.open("assentidecreto.csv", "w")

csv = CSV.read("tabella.csv", headers: true, col_sep: ",", skip_blanks: true)
c = 0
tot = 0
n = 0

if wikidata_mode
    wikidata_array = []
    different_array = []
end

# comune contiene il nome del comune
# gradi contiene i gradi giorno.
unless File.exist? "#{__dir__}/lista.txt"
    url = "https://petscan.wmflabs.org/?format=json&doit=&categories=Comuni%20d%27Italia&negcats=Comuni%20d%27Italia%20soppressi%0AFrazioni%20comunali%20d%27Italia&depth=8&project=wikipedia&lang=it&templates_yes=divisione%20amministrativa&show_redirects=no"
    petscan = HTTParty.get(url, timeout: 1000).to_h["*"][0]["a"]["*"]
    lista = File.open("#{__dir__}/lista.txt", "w")
    lista.write(petscan.to_json)
    lista.close
end
petscan = JSON.parse(File.read("#{__dir__}/lista.txt"))
province = JSON.parse(File.read("#{__dir__}/province.json")) # Lista province con regioni

puts 'Inizio a processare le pagine...'
begin
    bar = ProgressBar.new(csv.count)

    # pr,z,gr-g,alt,comune
    
    csv.each do |row|
        comune = row[4].upcase
        gradi = row[2]
    
        next if row[0].nil? || row[0] == "" || row[0] == "pr"  || comune.nil? || gradi.nil? || comune.strip == "" || gradi.strip == ""

        tot += 1
        # remove accents from string

        # stringaricerca = 'intitle:"' + comune.strip + '" comune italiano'
        # search = wikipedia.query(list: "search", srsearch: stringaricerca, srlimit: 1)
        
        # È adattato alla lista che è tutta in maiuscolo

        provincia = province.find { |p| p["sigla"] == row[0] }
        if petscan.select { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_"))}.count == 1
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (ITALIA)".gsub(" ", "_")} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (ITALIA)".gsub(" ", "_")}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (COMUNE)".gsub(" ", "_")} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (COMUNE)".gsub(" ", "_")}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (COMUNE ITALIANO)".gsub(" ", "_")} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (COMUNE ITALIANO)".gsub(" ", "_")}
            title = page["title"]
            item = page["q"]
        # verifica la regione come disambiguante
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (#{provincia["regione"].upcase})".gsub(" ", "_")} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (#{provincia["regione"].upcase})".gsub(" ", "_")}
            title = page["title"]
            item = page["q"]
        # verifica la provincia come disambiguante
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (#{provincia["nome"]})".gsub(" ", "_").upcase} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == "#{comune} (#{provincia["nome"]})".gsub(" ", "_").upcase}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("È","É").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join  == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("È","É").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("É","È").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("É","È").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_").gsub("-", "_"))} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_").gsub("-", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_").gsub("_", "-"))} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" ", "_").gsub("_", "-"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" - ", "-").gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub(" - ", "-").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("-", " - ").gsub(" ", "_"))} != nil
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("-", " - ").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        elsif petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("d'","di ").gsub(" ", "_"))} != nil 
            page = petscan.find { |e| e["title"].upcase.chars.map { |i| if i != e["title"].upcase[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join == (comune.upcase.chars.map { |i| if i != comune[-1] then i.tr("ÀÈÌÒÙÁÉÍÓÚ", "AEIOUAEIOU") else i end }.join.gsub("d'","di ").gsub(" ", "_"))}
            title = page["title"]
            item = page["q"]
        else
            puts "#{comune} non trovato"
            n += 1
            d.write("#{comune},#{gradi},nf")
            next
        end
        next if File.read("#{__dir__}/esclusioni.txt").split("\n").include?(page["title"])
                        

        wikitext = wikipedia.query prop: :revisions, titles: title, rvprop: :content, rvslots: "*"
          begin
                text = wikitext.data["pages"].first[1]["revisions"][0]["slots"]["main"]["*"]
                
                if text.match?(/\|\s*Gradi\sgiorno\s*=\s*(\d+)/i)
                        gradigiorno = gradi
                        match = text.match(/\|\s*Gradi\sgiorno\s*=\s*(\d+)/i)
                    if match[1] != gradigiorno
                        c += 1
                        f.write("#{title},#{match[1]},#{gradigiorno}\n")
                        if active
                            text.gsub!(/\|\s*Gradi\sgiorno\s*=\s*[\d\,\.]+\n*/i, "|Gradi giorno = #{gradigiorno}\n")
                            wikipedia.edit(title: title, text: text, summary: "Correzione dei gradi giorno secondo il DPR 412/93 così come aggiornato al 24-8-2016", bot: true)
                            puts "Pagina #{title} aggiornata con successo"
                        end
                    end
                else
                    puts "#{comune.strip} trovato #{title} e non matchabile (#{gradi})"
                    m.write("#{title},#{gradi}\n")
                    n += 1
                    if text.match?(/^\|\s*Gradi\sgiorno\s*=\s*$/im)
                        if active
                            gradigiorno = gradi
                            text.gsub!(/\|\s*Gradi\sgiorno\s*=\s*\n*/i, "|Gradi giorno = #{gradigiorno}\n")
                            wikipedia.edit(title: title, text: text, summary: "Aggiunta dei gradi giorno secondo il DPR 412/93 così come aggiornato al 24-8-2016", bot: true)
                            puts "Pagina #{title} aggiornata con successo"
                        end
                    end
                end

            # Verifica del dato su Wikidata
            if wikidata_mode
                check = HTTParty.get("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{item}&format=json&languages=en")
                
                is_there = check.to_hash["entities"][item]["claims"]["P9496"]

                if is_there.nil?
                    wikidata_array.push([item, gradigiorno])
                else
                    stated_gradigiorno = check.to_hash["entities"][item]["claims"]["P9496"][0]["mainsnak"]["datavalue"]["value"]["amount"]
                    
                    if stated_gradigiorno != "+#{gradigiorno}"
                        different_array.push([item, gradigiorno])
                        c += 1
                    end
                end
            end
          rescue => e
              puts "#{comune}: #{e}"
              n += 1
              next
          end
        bar.increment!
    end
rescue => e
    puts "Salvo..."
    f.close
    m.close
    d.close

    if wikidata_mode
      lista = File.open("#{__dir__}/wikidata.txt", "w")
      lista.write(wikidata_array.to_json)
      lista.close
  
      differenti = File.open("#{__dir__}/differenti.txt", "w")
      differenti.write(different_array.to_json)
      differenti.close
    end

    puts "#{e}: Elaborati #{tot} comuni di cui #{c} con discrepanze. Ci sono #{n} errori."
    puts "#{e.backtrace}"
end
f.close
m.close
d.close
if wikidata_mode
  lista = File.open("#{__dir__}/wikidata.txt", "w")
  lista.write(wikidata_array.to_json)
  lista.close

  differenti = File.open("#{__dir__}/differenti.txt", "w")
  differenti.write(different_array.to_json)
  differenti.close
end
puts "Elaborati #{tot} comuni di cui #{c} con discrepanze Ci sono #{n} errori.."