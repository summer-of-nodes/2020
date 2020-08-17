CREATE INDEX ON :Painting(id);
CREATE INDEX ON :Artist(name);
CREATE INDEX ON :Classification(name);
CREATE INDEX ON :Department(name);
create index on :MediumWord(name);

//paintings and classifications
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
CREATE (o:Painting {id:row.`Object ID`, title:row.Title, dateFrom:row.`Object Begin Date`, dateTo:row.`Object End Date`, url:row.`Link Resource`, culture:coalesce(row.Culture,'Unavailable')})
WITH o, split(row.Classification, '|') AS classifications
unwind classifications as classification
MERGE (c:Classification {name:classification})
WITH o, c
CREATE (o)-[:HAS_CLASSIFICATION]->(c);

//load the artists
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
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
CREATE (o)-[:IN_DEPARTMENT]->(d);

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
WITH row.Dimensions as size, row.`Object ID` as id
with apoc.text.regexGroups(size, '\\(( *[0-9]+(\\.[0-9]+)*( *[×x] *[0-9]+(\\.[0-9]+)*)) *cm\\)') as dim, id
with id, dim[0][1] as d
with id, apoc.text.split(d,'x|×') as e
MATCH (o:Painting {id:id})
SET o.dimensions = tofloat(trim(e[0]))*tofloat(trim(e[1]));

WITH ['XS','S','M', 'L', 'XL'] as sizes
UNWIND sizes AS size
CREATE (:PaintingSize {size:size});

MATCH (p:Painting)
WHERE exists(p.dimensions)
WITH p, CASE WHEN p.dimensions < 100 then "XS" when p.dimensions <500 then "S" when p.dimensions < 2800 then "M" when p.dimensions <11150 then "L" else "XL" end as size
MATCH (ps:PaintingSize {size:size})
CREATE (p)-[:HAS_SIZE]->(ps);

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
MATCH (o:Painting {id:row.`Object ID`})
MERGE (m:Medium {name:row.Medium})
CREATE (o)-[:HAS_MEDIUM]->(m);

MATCH (o:Painting)-[:HAS_MEDIUM]->(m:Medium)
WITH o, split(m.name, ' ') as names
FOREACH (n in names|
	MERGE (mw:MediumWord {name:apoc.text.clean(n)})
    CREATE (o)-[:HAS_MEDIUM_WORD]->(mw)
    );

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week2/MetPublicDomainPaintings.csv" AS row
MATCH (o:Painting {id:row.`Object ID`})
WITH o, split(row.Tags,'|') as tags
FOREACH (t in tags|
	MERGE (tag:Tag {name:t})
    CREATE (o)-[:HAS_TAG]->(tag)
);
