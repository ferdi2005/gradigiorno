// https://github.com/maxlath/wikibase-edit/blob/master/docs/how_to.md#set-reference
fs = require('fs')
var sleep = require('sleep'); 

var username = fs.readFileSync(".config", "utf-8").split("\n")[0]
var password = fs.readFileSync(".config", "utf-8").split("\n")[1]
const generalConfig = {
    instance: 'https://www.wikidata.org',
    credentials: {
        username: username,
        password: password
    },
    summary: "Adding degree day from official italian data",
    userAgent: 'ZonaSismicaBot@FerdiBot/v1.1 (https://ferdinando.me)',
    bot: true,
}
const wbEdit = require('wikibase-edit')(generalConfig);

var zones = JSON.parse(fs.readFileSync("wikidata.txt", "utf-8"));


function do_next() {
    var zone = zones[counter];
    wbEdit.claim.create({
            id: zone[0],
            property: "P9496",
            value: { amount: zone[1], unit: 'Q106651574'},
            references: [
                { P248: "Q125546223"},
                { P854: "https://www.normattiva.it/eli/stato/DECRETO_DEL_PRESIDENTE_DELLA_REPUBBLICA/1993/08/26/412/CONSOLIDATED", P813: new Date().toISOString().split('T')[0]}
            ]
        }).then( () => {
            console.log("Updated " + zone[0]);
            delete zones[counter];
            if (Object.keys(zones).length > 0) {
                counter += 1;
                do_next();
            }
        });
}

try {
    var counter = 0;
    do_next();
    fs.writeFileSync("new_wikidata.txt", JSON.stringify(zones), "utf8");
} catch (error) {
    fs.writeFileSync("new_wikidata.txt", JSON.stringify(zones), "utf8"); 
}

