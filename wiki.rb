# Comuni.csv
f = File.read("comuni.csv")
f = f.split("\n")
f.map! do |k|
    vk = "[[" + k.split(",")[0] + "]]"
    k = "#{vk},#{k.split(",")[1]},#{k.split(",")[2]}"
end
puts f.count
f.insert(0, "Comune,Gradi giorno su Wikipedia,Gradi giorno tabella")
puts f.join("\n")
puts "\n"

# Mancanti.csv
f = File.read("mancanti.csv")
f = f.split("\n")
f.map! do |k|
    vk = "[[" + k.split(",")[0] + "]]"
    k = "#{vk},#{k.split(",")[1]}"
end
puts f.count
f.insert(0, "Comune,Gradi giorno tabella")
puts f.join("\n")
