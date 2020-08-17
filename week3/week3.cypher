CREATE INDEX ON :GetFitNowCheckIn(date);
CREATE INDEX ON :FacebookEvent(date, eventId);
CREATE INDEX ON :Person(id);
CREATE INDEX ON :License(licenseNo);
CREATE INDEX ON :Vehicle(licenseNo);
CREATE INDEX ON :GetFitNow(id);
CREATE INDEX ON: Person(name);
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/crime_scene_report.csv" AS row
CREATE (csr:CrimeSceneReport {date:toInteger(row.date), type:row.type, description:row.description, city:row.city});
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/drivers_license.csv" AS row
CREATE (l:License {licenseNo:tointeger(row.id), age:tointeger(row.age), gender:row.gender, eyeColor:row.eye_color, hairColor:row.hair_color, height:toInteger(row.height)})
CREATE (v:Vehicle {licenseNo:tointeger(row.id),plateNumber:row.plate_number, carMake:row.car_make, carModel:row.car_model});
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/person.csv" AS row
CREATE (p:Person {id:row.id, name:row.name, addressNumber:toInteger(row.address_number), addressStreet:row.address_street_name, ssn:toInteger(row.ssn)});
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/person.csv" AS row
WITH tointeger(row.license_id) as license, row.id as id
MATCH (p:Person {id:id})
MATCH (l:License {licenseNo:license})
CREATE (p)-[:HAS_LICENSE]->(l)
WITH p, license
MATCH (v:Vehicle {licenseNo:license})
CREATE (p)-[:DRIVES]->(v)
REMOVE v.licenseNo;
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/facebook_event_checkin.csv" AS row
MERGE (f:FacebookEvent {date:row.date, eventId:row.event_id})
ON CREATE SET f.eventName = row.event_name
WITH f, row.person_id as person
MATCH (p:Person {id:person})
CREATE (p)-[:CHECKED_IN_EVENT]->(f);
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/get_fit_now_member.csv" AS row
CREATE (g:GetFitNow {id:row.id, startDate:toInteger(row.membership_start_date), status:row.membership_status})
with g, row.person_id as id
MATCH (p:Person {id:id})
CREATE (p)-[:HAS_MEMBERSHIP]->(g);
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/get_fit_now_check_in.csv" AS row
MERGE (gci:GetFitNowCheckIn {date:toInteger(row.check_in_date)})
WITH gci, row.membership_id as id
MATCH (g:GetFitNow {id:id})
CREATE (g)-[:GHECKED_IN_GYM]->(gci);
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/summer-of-nodes/2020/master/week3/interview.csv" AS row
CREATE (i:Interview {transcript:row.transcript})
with i, row.person_id as id
MATCH (p:Person{id:id})
CREATE (p)-[:GAVE]->(i);
