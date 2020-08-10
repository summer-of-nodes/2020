CREATE INDEX ON :Painting(id);
CREATE INDEX ON :Artist(name);
CREATE INDEX ON :Classification(name);
CREATE INDEX ON :Department(name);

//paintings and classifications
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
CREATE (o:Painting {id:row.`Object ID`, title:row.Title, dateFrom:row.`Object Begin Date`, dateTo:row.`Object End Date`, url:row.`Link Resource`, culture:coalesce(row.Culture,'Unavailable')})
WITH o, split(row.Classification, '|') AS classifications
unwind classifications as classification
MERGE (c:Classification {name:classification})
WITH o, c
CREATE (o)-[:HAS_CLASSIFICATION]->(c);

//load the artists
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2//MetPublicDomainPaintings.csv" AS row
MATCH (o:Painting {id:row.`Object ID`})
WITH split(coalesce(row.`Artist Display Name`, 'Unknown'), '|') AS artists, split(row.`Artist End Date`,'9999') AS endYears, o
WITH artists, endYears, range(0,size(artists)-1) as no, o
FOREACH (n IN no|
	MERGE (a:Artist {name:artists[n], endYear:coalesce(trim(endYears[n]),9999)})
    CREATE (o)-[:HAS_ARTIST]->(a));
MATCH (a:Artist) set a.endYear = toInteger(a.endYear);

//remove unknown artists
MATCH (a:Artist)
WHERE a.name contains('Unknown') OR a.name contains('Unidentified')
DETACH DELETE a;

//add departments
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
MERGE (d:Department {name:row.Department})
WITH d, row
MATCH (o:Painting {id:row.`Object ID`})
CREATE (o)-[:IN_DEPARTMENT]->(d)