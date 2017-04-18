-- drop what is there before so we don't conflict
-- with  other stuff.
DROP TABLE IF EXISTS Org CASCADE;
DROP TABLE IF EXISTS Meet CASCADE;
DROP TABLE IF EXISTS Participant CASCADE;
DROP TABLE IF EXISTS Event CASCADE;
DROP TABLE IF EXISTS Stroke CASCADE;
DROP TABLE IF EXISTS Distance CASCADE;
DROP TABLE IF EXISTS Heat CASCADE;
DROP TABLE IF EXISTS Leg CASCADE;
DROP TABLE IF EXISTS StrokeOf CASCADE;
DROP TABLE IF EXISTS Swim CASCADE;
DROP TABLE IF EXISTS Remind CASCADE;
DROP TABLE IF EXISTS RemindPrimaryKey CASCADE;
DROP TABLE IF EXISTS RemindNotPK CASCADE;
DROP TABLE IF EXISTS ErrorOutput CASCADE;
DROP FUNCTION IF EXISTS InsertParticipant;


CREATE TABLE ErrorOutput(ErrorCount INTEGER, 
	                 ErrorMessage VARCHAR(350),
	                 PRIMARY KEY(ErrorCount));

CREATE TABLE Org(id VARCHAR(20), 
                 name VARCHAR(150) NOT NULL, 
                 is_univ BOOLEAN,
                 PRIMARY KEY(id));


CREATE TABLE Meet(name VARCHAR(200), 
	start_date DATE, 
	num_days INTEGER, 
	org_id VARCHAR(20),
        FOREIGN KEY (org_id) REFERENCES Org (id), 
        PRIMARY KEY(name)); 

CREATE TABLE Participant(id VARCHAR(20), 
	                 name VARCHAR(50),
	                 gender VARCHAR,
	                 org_id VARCHAR(20),
                         FOREIGN KEY (org_id) REFERENCES Org (id), 
	                 PRIMARY KEY(id));

CREATE TABLE Distance(distance INTEGER, 
                      PRIMARY KEY (distance));

CREATE TABLE Stroke(stroke VARCHAR(20), 
                      PRIMARY KEY (stroke));

CREATE TABLE Leg(leg INTEGER, 
                      PRIMARY KEY (leg));

CREATE TABLE Event(id VARCHAR(20), 
	           gender VARCHAR, 
	           distance INTEGER, 
	           FOREIGN KEY (distance) REFERENCES Distance(distance),
                   PRIMARY KEY (id));

CREATE TABLE StrokeOf(event_id VARCHAR(20),
	              leg INTEGER,
	              stroke VARCHAR(20), 
                      FOREIGN KEY (stroke) REFERENCES Stroke (stroke) ,
                      FOREIGN KEY (leg) REFERENCES Leg (leg) ,
                      FOREIGN KEY (event_id) REFERENCES Event (id) ,
                      PRIMARY KEY (event_id, leg));

CREATE TABLE Heat(id VARCHAR(20), 
	          event_id VARCHAR(20), 
	          meet_name VARCHAR(200), 
	          FOREIGN KEY (event_id) REFERENCES Event(id),
	          FOREIGN KEY (meet_name) REFERENCES Meet(name),
                  PRIMARY KEY (id, event_id, meet_name));
CREATE TABLE Swim(heat_id VARCHAR(20), 
	          event_id VARCHAR(20), 
	          meet_name VARCHAR(200), 
	          participant_id VARCHAR(20), 
	          leg INTEGER, 
	          time REAL,  --in seconds
	          FOREIGN KEY (heat_id, event_id, meet_name) REFERENCES Heat(id, event_id, meet_name),
	          FOREIGN KEY (participant_id) REFERENCES Participant(id),
	          FOREIGN KEY (leg) REFERENCES Leg(leg),
                  PRIMARY KEY (heat_id, event_id, meet_name, participant_id));

CREATE TABLE Remind(TableName VARCHAR(50), 
	            Reminder VARCHAR(500),
	            PRIMARY KEY(TableName));
CREATE TABLE RemindPrimaryKey(TableName VARCHAR(50), 
	            Reminder VARCHAR(500),
	            PRIMARY KEY(TableName));
CREATE TABLE RemindNotPK(TableName VARCHAR(50), 
	            Reminder VARCHAR(500),
	            PRIMARY KEY(TableName));
----
CREATE OR REPLACE FUNCTION GetPrimaryKey(table_name VARCHAR)
    RETURNS VARCHAR(20) AS
$$ 
   BEGIN
   	RETURN (SELECT reminder FROM  RemindPrimaryKey WHERE TableName=table_name);
   END; $$ --end function
LANGUAGE 'plpgsql';
----
CREATE OR REPLACE FUNCTION GetNotPrimaryKey(table_name VARCHAR)
    RETURNS VARCHAR(20) AS
$$ 
   BEGIN
   	RETURN (SELECT reminder FROM  RemindNotPK WHERE TableName=table_name);
   END; $$ --end function
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION RecordError(Msg VARCHAR)
    RETURNS VOID AS 
$$ 
    DECLARE 
      cnt INT;
    BEGIN
    cnt:= (SELECT Count( ErrorCount ) FROM ErrorOutput);
    cnt:=cnt+1;
    INSERT INTO ErrorOutput VALUES
      (cnt, Msg);
    
   END; $$ --end function
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION InsertOrg(org_id VARCHAR(20), 
	                             org_name VARCHAR(150),
	                             org_is_univ BOOLEAN)
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
       matches := (SELECT COUNT (*) FROM Org WHERE org_id=id);
       IF matches = 0 THEN
          INSERT INTO Org VALUES (org_id, org_name, org_is_univ);
       ELSE
          UPDATE  Org SET name=org_name, is_univ=org_is_univ
             	              WHERE id=org_id;
       END IF ;
    END; $$
LANGUAGE 'plpgsql';
--add IMMUTABLE??? What does that do?


----
--insert into this table.   foreign key exists
--if the primary key already exists, overwrite it.  (as per the requirements,
--which say to delete data if new conflicts with old)
--TABLE Meet(name VARCHAR(200), start_date DATE, 
--	num_days INTEGER, org_id VARCHAR(20),
--      FOREIGN KEY (org_id) REFERENCES Org (id), 
--      PRIMARY KEY(name)); 
CREATE OR REPLACE FUNCTION InsertMeet(meet_name VARCHAR(200), 
	                             meet_start_date DATE,
	                             meet_num_days INTEGER,
                                     meet_org_id VARCHAR(20))
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
      
       --check foreign key is in Org
       matches := (SELECT COUNT (*) FROM Org WHERE meet_org_id=id);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert Meet ', meet_name, 
          		 ' not inserted.  Org ', meet_org_id, ' not found.'));
          RETURN;
       END IF;
       --then check for unique primary key
       matches := (SELECT COUNT (*) FROM Meet  WHERE meet_name=name);
       IF matches = 0 THEN
       	  
          INSERT INTO Meet VALUES (meet_name,meet_start_date, meet_num_days,
             	                      meet_org_id);
       ELSE
           UPDATE  Meet SET start_date=meet_start_date, 
                              num_days=meet_num_days,
             	              org_id= meet_org_id WHERE name=meet_name;
       END IF ;
    END; $$
LANGUAGE 'plpgsql';

--add IMMUTABLE??? What does that do?


-- CREATE TABLE Stroke(stroke VARCHAR(20), 
--                      PRIMARY KEY (stroke));

CREATE OR REPLACE FUNCTION InsertStroke(stroke_stroke VARCHAR(20))
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
       matches := (SELECT COUNT (*) FROM Stroke WHERE stroke_stroke=stroke);
       IF matches = 0 THEN
          INSERT INTO Stroke VALUES (stroke_stroke);
       END IF ;
    END; $$
LANGUAGE 'plpgsql';
--add IMMUTABLE??? What does that do?

CREATE OR REPLACE FUNCTION CheckGender( c_gender VARCHAR)
    RETURNS VARCHAR AS 
$$
    DECLARE 
      ret_gender VARCHAR;
    BEGIN
    ret_gender:='X';
    IF(c_gender='F' OR c_gender= 'f') THEN
      ret_gender:='F';
    ELSE 
      IF(c_gender='M' OR c_gender= 'm') THEN
         ret_gender:='M';
      END IF;	
    END IF;  
    RETURN ret_gender;
END;
$$
LANGUAGE 'plpgsql';

--CREATE TABLE Participant(id VARCHAR(20), 
--	                 name VARCHAR(50),
--	                 gender VARCHAR,
--	                 org_id VARCHAR(20),
--                       FOREIGN KEY (org_id) REFERENCES Org (id), 
--	                 PRIMARY KEY(id));
CREATE OR REPLACE FUNCTION InsertParticipant(par_id VARCHAR(20), 
	                         par_gender VARCHAR,
                                 par_org_id VARCHAR(20),
	                         par_name VARCHAR(50))
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
      insert_gender VARCHAR;
    BEGIN
       --check foreign key is in Org
       matches := (SELECT COUNT (*) FROM Org WHERE par_org_id=id);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert Participant ', par_name, 
          		 ' not inserted.  Org ', par_org_id, ' not found.'));
          RETURN;
       END IF;
       --check gender --capialize and make sure m/f
       insert_gender:=CheckGender( par_gender );
       IF insert_gender='X' THEN --error in the gender
          PERFORM RecordError(CONCAT('On Insert Participant ', par_name, 
          		 ' not inserted.  Gender ', par_gender, ' not valid.'));
          RETURN;
       END IF;

       --then check for unique primary key
       matches := (SELECT COUNT (*) FROM Participant  WHERE par_id=id);
       IF matches = 0 THEN
       	  
           INSERT INTO Participant VALUES (par_id, par_name, insert_gender, 
           	                      par_org_id);
       ELSE
             UPDATE  Participant SET name=par_name, gender=insert_gender,
             	              org_id= par_org_id WHERE id=par_id;
       END IF;
    END; $$
LANGUAGE 'plpgsql';
--add IMMUTABLE??? What does that do?

--TABLE Distance(distance INTEGER, 
--               PRIMARY KEY (distance));

CREATE OR REPLACE FUNCTION InsertDistance(dist_distance INTEGER)
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
       IF dist_distance >0 THEN 
         matches := (SELECT COUNT (*) FROM Distance WHERE 
         	                                    dist_distance=distance);
         IF matches = 0 THEN
            INSERT INTO Distance VALUES (dist_distance);
         END IF ;
       END IF ;
    END; $$
LANGUAGE 'plpgsql';

--TABLE Leg(leg INTEGER, 
--                      PRIMARY KEY (leg));

CREATE OR REPLACE FUNCTION InsertLeg(leg_leg INTEGER)
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
       IF leg_leg >0 THEN 
         matches := (SELECT COUNT (*) FROM Leg WHERE leg_leg=leg);
         IF matches = 0 THEN
            INSERT INTO Leg VALUES (leg_leg);
         END IF ;
       END IF ;
    END; $$
LANGUAGE 'plpgsql';


--TABLE Heat(id VARCHAR(20), 
--	         event_id VARCHAR(20), 
--	          meet_name VARCHAR(200), 
--	          FOREIGN KEY (event_id) REFERENCES Event(id),
--	          FOREIGN KEY (meet_name) REFERENCES Meet(name),
--                  PRIMARY KEY (id, event_id, meet_name));
CREATE OR REPLACE FUNCTION InsertHeat(heat_id VARCHAR(20), 
	                             heat_event_id  VARCHAR(20),
	                             heat_meet_name VARCHAR(200))
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
      
       --check foreign key is in Event
       matches := (SELECT COUNT (*) FROM Event WHERE heat_event_id=id);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert Heat ', heat_id, heat_event_id,
                    heat_meet_name, 
          	    ' not inserted.  Event ', heat_event_id, ' not found.'));
          RETURN;
       END IF;

       --check foreign key is in Meet
       matches := (SELECT COUNT (*) FROM Meet WHERE heat_meet_name=name);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert Heat ', heat_id, heat_event_id,
                    heat_meet_name, 
          	    ' not inserted.  Meet ', heat_meet_name, ' not found.'));
          RETURN;
       END IF;

       --then check for unique primary key
       matches := (SELECT COUNT (*) FROM Heat  WHERE heat_id=id AND
            	         heat_event_id=event_id AND heat_meet_name=meet_name);
       IF matches = 0 THEN
       	  
           INSERT INTO Heat VALUES (heat_id,heat_event_id, heat_meet_name);
              --no else, since the whole thing is a primary key and
              --the whole thing matches
      END IF ;--end chck for primary key heat already used

    END; $$ --end function
LANGUAGE 'plpgsql';

--CREATE TABLE Event(id VARCHAR(20), 
--	           gender VARCHAR, 
--	           distance INTEGER, 
--	           FOREIGN KEY (distance) REFERENCES Distance(distance),
--                   PRIMARY KEY (id));

CREATE OR REPLACE FUNCTION InsertEvent(ev_id VARCHAR(20), 
	                         ev_gender VARCHAR,
                                 ev_distance INTEGER)
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
       --check foreign key is in distance
       matches := (SELECT COUNT (*) FROM Distance WHERE ev_distance=distance);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert Event ', ev_id, 
          	    ' not inserted.  Distance ', ev_distance, ' not found.'));
          RETURN;
       END IF;

       --then check for unique primary key
        matches := (SELECT COUNT (*) FROM Event  WHERE ev_id=id);
        IF matches = 0 THEN
        
           INSERT INTO Event VALUES (ev_id, ev_gender, ev_distance);
        ELSE
             UPDATE  Event SET distance=ev_distance, gender=ev_gender
           	              WHERE id=ev_id;
        END IF ;--primary key is found
    END; $$ --end function
LANGUAGE 'plpgsql';
--add IMMUTABLE??? What does that do?



--CREATE TABLE StrokeOf(event_id VARCHAR(20),
--	              leg INTEGER,
--	              stroke VARCHAR(20), 
--                     FOREIGN KEY (stroke) REFERENCES Stroke (stroke) ,
--                      FOREIGN KEY (leg) REFERENCES Leg (leg) ,
--                      FOREIGN KEY (event_id) REFERENCES Event (id) ,
--                      PRIMARY KEY (event_id, leg));

CREATE OR REPLACE FUNCTION InsertStrokeOf(so_event_id VARCHAR(20), 
	                                 so_leg  INTEGER,
	                                 so_stroke VARCHAR(20))
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
    BEGIN
      
       --check foreign key is in Event
       matches := (SELECT COUNT (*) FROM Event WHERE so_event_id=id);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert StrokeOf ', so_event_id, 
          		 so_leg, ' not inserted.  Event ', so_event_id, 
          		' not found.'));
          RETURN;
       END IF;

       --check foreign key is in Leg
       matches := (SELECT COUNT (*) FROM Leg WHERE so_leg=leg);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert StrokeOf ', so_event_id, 
         	 so_leg, ' not inserted.  Leg ', so_leg, ' not found.'));
          RETURN;
       END IF;

       --check foreign key is in Stroke
       matches := (SELECT COUNT (*) FROM Stroke WHERE so_stroke=stroke);
       IF matches <= 0 THEN
          PERFORM RecordError(CONCAT('On Insert StrokeOf ', so_event_id, 
         	 so_leg, ' not inserted.  Stroke ', so_stroke, ' not found.'));
          RETURN;
       END IF;
       	  
       --then check for unique primary key
       matches := (SELECT COUNT (*) FROM StrokeOf  WHERE so_event_id=event_id AND so_leg=leg);
         IF matches = 0 THEN
             INSERT INTO StrokeOf VALUES (so_event_id,so_leg, so_stroke);
         ELSE
             UPDATE  StrokeOf SET stroke=so_stroke
             	              WHERE so_event_id=event_id AND so_leg=leg;
	 END IF ;--end chck for primary key StrokeOf already used

    END; $$ --end function
LANGUAGE 'plpgsql';

--returns if event is a relay
--I'm just saying that a heat is a relay only if there are more than 1
--legs.  
CREATE OR REPLACE FUNCTION IsRelay(ir_heat_id VARCHAR(20), 
	                          ir_event_id VARCHAR(20), 
	                           ir_meet_name VARCHAR(200))
    RETURNS BOOLEAN AS 
$$
    DECLARE 
      count INTEGER ;
    BEGIN
       count := (SELECT  COUNT ( DISTINCT leg) FROM Swim WHERE 
       	         ir_heat_id=heat_id AND ir_event_id=event_id AND 
       	        ir_meet_name=meet_name);
       RETURN count > 1 ; 
    END; $$ --end function
LANGUAGE 'plpgsql';



--TABLE Swim(heat_id VARCHAR(20), 
--	          event_id VARCHAR(20), 
--	          meet_name VARCHAR(200), 
--	          participant_id VARCHAR(20), 
--	          leg INTEGER, 
--	          time REAL,  --in seconds
--	          FOREIGN KEY (heat_id, event_id, meet_name) REFERENCES Heat(id, event_id, meet_name),
--	          FOREIGN KEY (participant_id) REFERENCES Participant(id),
--	          FOREIGN KEY (leg) REFERENCES Leg(leg),
--                 PRIMARY KEY (heat_id, event_id, meet_name, participant_id));
--Just for testing.

CREATE OR REPLACE FUNCTION InsertSwim(sw_heat_id VARCHAR(20), 
	                    sw_event_id VARCHAR(20), sw_meet_name VARCHAR(200),
	                    sw_participant_id VARCHAR(20), sw_leg INTEGER,
	                    sw_time REAL)
    RETURNS VOID AS 
$$
    DECLARE 
      matches INT;
      leg_matches INT;
      swimmer_gender VARCHAR;
      event_gender VARCHAR;
      participant_to_remove_id VARCHAR(20);
    BEGIN
      
       --check foreign key is in Heat
       matches := (SELECT COUNT (*) FROM Heat WHERE sw_heat_id=id AND 
       	                      sw_event_id=event_id AND sw_meet_name=meet_name);
       IF matches <=0 THEN
          PERFORM RecordError(CONCAT('On Insert Swim ', sw_heat_id, ' ',
          		  sw_event_id, ' ', sw_meet_name, ' ', 
          		  sw_participant_id, 
          		 ' not inserted.  ',  'Heat not valid.'));
       	 RETURN; 
       END IF; 

       --check foreign key is in Participant
       matches := (SELECT COUNT (*) FROM Participant WHERE 
       	                               sw_participant_id=id );
       IF matches <=0 THEN
          PERFORM RecordError(CONCAT('On Insert Swim ', sw_heat_id, ' ',
          		  sw_event_id, ' ', sw_meet_name, ' ', 
          		  sw_participant_id, 
          		 ' not inserted.  ',  'Participant not valid.'));
       	 RETURN; 
       END IF; 

       --check gender --capialize and make sure m/f
       swimmer_gender:=CheckGender((SELECT gender FROM Participant WHERE 
       	                           id=sw_participant_id ));
       event_gender:=CheckGender((SELECT gender FROM Event WHERE 
       	                           id=sw_event_id ));
       IF swimmer_gender <> event_gender THEN --error in the gender
          PERFORM RecordError(CONCAT('On Insert Swim ', sw_heat_id, ' ',
          		  sw_event_id, ' ', sw_meet_name, ' ', 
          		  sw_participant_id, ' not inserted.  ',  
          		' Event-Swimmer Gender Mismatch.'));
          RETURN;
       END IF;
      
       -- now check foreign key is in leg
       --check foreign key is in Participant
       matches := (SELECT COUNT (*) FROM Leg WHERE sw_leg=leg);
       IF matches <=0 THEN
          PERFORM RecordError(CONCAT('On Insert Swim ', sw_heat_id, ' ',
          		  sw_event_id, ' ', sw_meet_name, ' ', 
          		  sw_participant_id, 
          		 ' not inserted.  ',  'Leg ', sw_leg, ' not valid.'));
       	 RETURN; 
       END IF; 
       --then check for unique primary key
       matches := (SELECT COUNT (*) FROM Swim  WHERE 
              	                  sw_heat_id=heat_id 
              	              AND sw_event_id=event_id 
              	              AND sw_meet_name=meet_name 
              	              AND sw_participant_id=participant_id);
        -- now check for relay.  
        -- for a relay, each school can only have 1 swimmer per leg
        -- for not a realy, each school can have multiple swimmers
        IF (IsRelay(sw_heat_id, sw_event_id, sw_meet_name)) THEN 
            --relay, so check for leg and team combo, too
          leg_matches := 
        (SELECT COUNT (*) FROM 
           (SELECT * FROM 
           	     (SELECT * FROM Swim WHERE 
           	     	 meet_name=sw_meet_name 
           	     	AND event_id=sw_event_id 
           	     	AND heat_id=sw_heat_id ) as foo
           	INNER JOIN Participant ON participant_id=id) as foo2
        WHERE foo2.leg=sw_leg and 
        foo2.org_id IN (SELECT org_id FROM Participant WHERE id=sw_participant_id))
        ;
          IF (matches <1) AND (leg_matches < 1) THEN
               --primary key ok, and leg doesn't exist for this school
             INSERT INTO Swim VALUES (sw_heat_id, sw_event_id, sw_meet_name, 
                  sw_participant_id, sw_leg, sw_time);
          END IF;
          IF (matches >=1) AND  (leg_matches <1) THEN
             --pk used, but new leg is fine.  use update
             UPDATE  Swim SET leg=sw_leg, time=sw_time
             	              WHERE sw_heat_id=heat_id 
             	                   AND sw_event_id=event_id 
             	                   AND sw_meet_name=meet_name 
             	                   AND sw_participant_id=participant_id;
          END IF;
          IF (matches <1) AND (leg_matches>=1) THEN
             --pk is fine, but new leg is used. remove old leg, then
             --add this leg.
             --find the old leg to remove
             participant_to_remove_id:=
                (SELECT par_id  FROM
            	   (SELECT Participant.id AS par_id, sw1.leg as leg,
            	   	Participant.org_id as org_id FROM
            	           (SELECT participant_id, leg FROM Swim   
            	       	         WHERE sw_heat_id=heat_id 
            	                  AND sw_event_id=event_id 
              	                  AND sw_meet_name=meet_name ) AS sw1
                                INNER JOIN Participant 
              	              	  on  Participant.id=sw1.participant_id) AS sw2 
              	                WHERE sw2.leg=sw_leg 
              	                AND sw2.org_id=(SELECT org_id FROM Participant 
              	                	        WHERE id=sw_participant_id));
             --remove it
             DELETE FROM Swim WHERE sw_heat_id=heat_id 
             	                   AND sw_event_id=event_id 
             	                   AND sw_meet_name=meet_name 
             	                   AND participant_to_remove_id=participant_id;
             --add the new leg 
             INSERT INTO Swim VALUES (sw_heat_id, sw_event_id, sw_meet_name, 
                  sw_participant_id, sw_leg, sw_time);
        
          END IF;
          IF (matches >=1) AND (leg_matches>=1) THEN
             --pk needs to be updated, and new leg is used. remove old leg, then
             --update this leg.
             --find the old leg to remove
             participant_to_remove_id:=
                     (SELECT par_id FROM 
            	          (SELECT Participant.id as par_id, sw1.leg as leg, 
            	   	Participant.org_id as org_id FROM
            	               (SELECT participant_id, leg FROM Swim   
            	       	         WHERE sw_heat_id=heat_id 
            	                  AND sw_event_id=event_id 
              	                  AND sw_meet_name=meet_name ) AS sw1
                                INNER JOIN Participant 
              	              	  on  Participant.id=sw1.participant_id) AS sw2 
              	                WHERE leg=sw_leg
              	                AND sw2.org_id=(SELECT org_id FROM Participant 
              	                	        WHERE id=sw_participant_id));
             --remove it
             --actually, make sure I'm not deleting myself
             IF (sw_participant_id <>participant_to_remove_id) THEN
                 DELETE FROM Swim WHERE sw_heat_id=heat_id 
             	                   AND sw_event_id=event_id 
             	                   AND sw_meet_name=meet_name 
             	                   AND participant_to_remove_id=participant_id;
             END IF;
             --add the new leg 
             UPDATE  Swim SET leg=sw_leg, time=sw_time
             	              WHERE sw_heat_id=heat_id 
             	                   AND sw_event_id=event_id 
             	                   AND sw_meet_name=meet_name 
             	                   AND sw_participant_id=participant_id;
          END IF;
        ELSE --not a relay, so just check pk.
       	  IF(matches<=0) THEN --primary key not used yet
             INSERT INTO Swim VALUES (sw_heat_id, sw_event_id, sw_meet_name, 
                  sw_participant_id, sw_leg, sw_time);
          ELSE --primarykey is used, so update
             UPDATE  Swim SET leg=sw_leg, time=sw_time
             	              WHERE sw_heat_id=heat_id 
             	                   AND sw_event_id=event_id 
             	                   AND sw_meet_name=meet_name 
             	                   AND sw_participant_id=participant_id;

          END IF; --inside not a relay, and if pk is unique
	END IF ;  --relay 
    END; $$ --end function
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION ClearError()
    RETURNS VOID AS 
$$ BEGIN
   DELETE FROM  ErrorOutput ;
    
   END; $$ --end function
LANGUAGE 'plpgsql';





CREATE OR REPLACE FUNCTION MakeHeatSheetFull4()
    RETURNS TABLE(
       meet VARCHAR(200), event VARCHAR(20), distance INTEGER, stroke VARCHAR(20),  
       heat VARCHAR(20), swimmer VARCHAR(50),
       swimmer_id VARCHAR(20), is_relay BOOLEAN,
       team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ BEGIN
RETURN QUERY

SELECT DISTINCT
       foo1.meet, foo1.event, foo1.distance, StrokeOf.stroke, foo1.heat, foo1.swimmer, 
       foo1.swimmer_id, foo1.is_relay, foo1.team, foo1.race_time, foo1.rank
 FROM
    (SELECT * From (SELECT * FROM  MakeHeatSheetFull1())  as foo
	 INNER JOIN
	 Event on event.id=foo.event) as foo1  
	    INNER JOIN 
	    StrokeOf ON foo1.event=event_id

      ;    
    END; $$ --end function
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION MakeHeatSheetFull2()
    RETURNS TABLE(
       meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
       heat VARCHAR(20), swimmer VARCHAR(50),
       swimmer_id VARCHAR(20), is_relay BOOLEAN,
       team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ BEGIN
RETURN QUERY

SELECT DISTINCT
       foo1.meet, foo1.distance, StrokeOf.stroke, foo1.heat, foo1.swimmer, 
       foo1.swimmer_id, foo1.is_relay, foo1.team, foo1.race_time, foo1.rank
 FROM
    (SELECT * From (SELECT * FROM  MakeHeatSheetFull1())  as foo
	 INNER JOIN
	 Event on event.id=foo.event) as foo1  
	    INNER JOIN 
	    StrokeOf ON foo1.event=event_id

      ;    
    END; $$ --end function
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION MakeHeatSheetFull1()
    RETURNS TABLE(
  meet VARCHAR(200), event VARCHAR(20),  heat VARCHAR(20), swimmer VARCHAR(50),
  swimmer_id VARCHAR(20), is_relay BOOLEAN,
 team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ BEGIN
RETURN QUERY
---need to make it return the sheet
----------------------------------------------
--first get the relays,then union all with the swimmers

--select puts the same column headings as the swimmers only, makes the
--swimmer field a "relay team"
-- and ranks the teams by time
		(SELECT meet_name as meet, event_id as event, heat_id as heat, 'Relay Team' as swimmer,  NULL as swimmer_id, TRUE as is_realy, team_name as team, team_time as time,
    RANK() OVER (PARTITION BY foo3.meet_name, foo3.event_id, foo3.heat_id  ORDER BY team_time  )

    FROM 
---this select changes from org id to the team name
(SELECT meet_name, event_id, heat_id ,  Org.name as team_name , team_time 
FROM 
--this select sums the team times
    (SELECT  foo2.meet_name, foo2.event_id, foo2.heat_id, foo2.team_name, SUM(time )as team_time FROM 
 --uses the known relays to get all the swim information assiciated with it
(SELECT relay_list.meet_name as meet_name, relay_list.event_id as event_id, 
relay_list.heat_id as heat_id, relay_list.team_name as team_name, 
foo.leg as leg, foo.time as time, foo.id as id
FROM
--after i figure out what is a relay select  the important field to pass
(SELECT meet_name,  event_id, heat_id, org_id as team_name FROM 
--determine if it is a relay based on number of legs
(SELECT heat_id, event_id, meet_name, org_id, COUNT( DISTINCT leg) > 1 as is_relay FROM 
--maps the participant to team for leg counting
(SELECT heat_id, event_id, meet_name, participant_id, org_id, leg FROM 
   Swim 
LEFT JOIN Participant on id=participant_id) AS hs1
group by heat_id, event_id, meet_name, org_id) AS hs2
WHERE hs2.is_relay) AS relay_list
INNER  JOIN 
--looks swims on the swimmer same team, same evnet, heat, meet
(SELECT *  FROM Swim INNER JOIN Participant ON id=participant_id) AS foo ON 
foo.meet_name=relay_list.meet_name AND
foo.event_id=relay_list.event_id AND
foo.heat_id=relay_list.heat_id AND
foo.org_id=relay_list.team_name) as foo2
GROUP BY foo2.meet_name, foo2.event_id, foo2.heat_id, foo2.team_name)  as foo4
LEFT JOIN Org on Org.id=foo4.team_name)
as foo3)

UNION ALL
(SELECT meet_name as Meet, event_id as Event,  heat_id as Heat,  
        participant_name as  Swimmer,   participant_id as swimmer_id, 
        FALSE as is_relay,
       Org.name as Team, time as Time, 
       Rank() Over (Partition BY event_id, heat_id meet_name ORDER BY time ) as Rank
FROM

(SELECT heat_id,  event_id, meet_name,  HS4.gender as gender, distance, 
       participant_id, Participant.name as participant_name, Participant.gender 
       as participant_gender, org_id, leg, time, 
       stroke
FROM
(SELECT heat_id , HS3.event_id as event_id, meet_name,  gender, 
       distance, participant_id, HS3.leg as leg, time, stroke
FROM
(SELECT HS2.heat_id as heat_id, HS2.event_id as event_id, 
       HS2.meet_name as meet_name, HS2.gender as gender, 
       HS2.distance as distance, participant_id, leg, time
FROM 
( SELECT heat_id, event_id, meet_name, gender, distance
FROM (          (SELECT id as heat_id, event_id, meet_name
                 FROM Heat) AS HS1
      LEFT JOIN Event ON HS1.event_id=Event.id) ) As HS2
      LEFT JOIN Swim ON Swim.heat_id=HS2.heat_id AND 
                        Swim.event_id=HS2.event_id AND
                        Swim.meet_name=HS2.meet_name) AS HS3
      LEFT JOIN StrokeOf on HS3.event_id=StrokeOf.event_id AND
                      HS3.leg=StrokeOf.leg) AS HS4
      LEFT JOIN Participant on Participant.id=HS4.participant_id) AS HS5
      LEFT JOIN Org on HS5.org_id=Org.id
      ORDER BY meet_name, event_id, heat_id, is_relay, rank)
      ;    
    END; $$ --end function
LANGUAGE 'plpgsql';
--add IMMUTABLE??? What does that do?

CREATE OR REPLACE FUNCTION MakeHeatSheetMeet4(
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
        meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
        heat VARCHAR(20), swimmer VARCHAR(50), swimmer_id VARCHAR(20),
        team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY (SELECT foo.meet, foo.distance, foo.stroke, foo.heat, 
 	foo.swimmer, foo.swimmer_id, foo.team, foo.race_time, foo.rank

 	        FROM (SELECT * FROM  MakeHeatSheetFull4())  AS foo
 	WHERE foo.meet=mhs_meet_name
 	ORDER BY foo.meet, foo.event, foo.heat,foo.is_relay,foo.rank
        
) 
;   

    END; $$ --end function
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION MakeHeatSheetParticipantMeet4(
	                     mhs_participant_id VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
        meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
        heat VARCHAR(20), swimmer VARCHAR(50), swimmer_id VARCHAR(20),
        team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY 

    (SELECT foo.meet, foo.distance, foo.stroke, foo.heat, foo.swimmer,
 	        foo.swimmer_id, foo.team, foo.race_time, foo.rank
 	         FROM (SELECT * FROM MakeHeatSheetFull4()) as foo
 	         WHERE foo.meet=mhs_meet_name AND
 	         foo.swimmer_id=mhs_participant_id );
    END; $$ --end function
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION MakeHeatSheetParticipantMeet5(
	                     mhs_participant_id VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
        meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
        heat VARCHAR(20), swimmer VARCHAR(50), swimmer_id VARCHAR(20),
        team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY 

---people only
    (SELECT foo.meet, foo.distance, foo.stroke, foo.heat, foo.swimmer,
 	        foo.swimmer_id, foo.team, foo.race_time, foo.rank
 	         FROM (SELECT * FROM MakeHeatSheetFull4()) as foo
 	         WHERE foo.meet=mhs_meet_name AND
 	         foo.swimmer_id=mhs_participant_id )

	--now get relays
	UNION ALL

    (SELECT 
    	foo3.meet, foo3.distance, foo3.stroke, foo3.heat, foo3.swimmer,
 	        foo3.swimmer_id, foo3.team, foo3.race_time, foo3.rank
 	         FROM (SELECT * FROM MakeHeatSheetFull4()) as foo3
 	         WHERE foo3.meet=mhs_meet_name AND
 	         foo3.is_relay=TRUE  AND foo3.event IN
                (SELECT foo2.event 
 	         FROM (SELECT * FROM MakeHeatSheetFull4()) as foo2
 	         WHERE foo2.meet=mhs_meet_name AND
 	         foo2.swimmer_id=mhs_participant_id )
 	        AND foo3.team IN
                (SELECT foo2.team 
 	         FROM (SELECT * FROM MakeHeatSheetFull4()) as foo2
 	         WHERE foo2.meet=mhs_meet_name AND
 	         foo2.swimmer_id=mhs_participant_id )
 	
)
 	;
    END; $$ --end function
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION MakeHeatSheetEventMeet(
	                     mhs_event VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
        meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
        heat VARCHAR(20), swimmer VARCHAR(50), swimmer_id VARCHAR(20),
        team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY (SELECT foo.meet, foo.distance, foo.stroke, foo.heat, 
 	foo.swimmer, foo.swimmer_id, foo.team, foo.race_time, foo.rank
 	        FROM (SELECT * FROM  MakeHeatSheetFull4())  AS foo
 	WHERE foo.meet=mhs_meet_name AND foo.event=mhs_event
 	ORDER BY foo.is_relay,foo.race_time
) 
;   

    END; $$ --end function
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION MakeHeatSheetSchoolMeet4(
	                     mhs_school_id VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
        meet VARCHAR(200), distance INTEGER, stroke VARCHAR(20),  
        heat VARCHAR(20), swimmer VARCHAR(50), swimmer_id VARCHAR(20),
        team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY (SELECT foo.meet, foo.distance, foo.stroke, foo.heat, 
 	foo.swimmer, foo.swimmer_id, foo.team, foo.race_time, foo.rank

 	        FROM (SELECT * FROM  MakeHeatSheetFull4())  AS foo
 	WHERE foo.meet=mhs_meet_name AND foo.team=mhs_school_id
 	ORDER BY foo.meet, foo.event, foo.heat,foo.is_relay,foo.rank
) 
;   

    END; $$ --end function
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION MakeHeatSheetSchoolMeet2(
	                     mhs_school_id VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
  meet VARCHAR(200), event VARCHAR(20),  heat VARCHAR(20), swimmer VARCHAR(50),
  swimmer_id VARCHAR(20),
 team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY (SELECT foo.meet, foo.event, foo.heat, foo.swimmer, 
 	foo.swimmer_id, foo.team, foo.race_time, foo.rank
 	       FROM (SELECT * FROM MakeHeatSheetFull1()) as foo
                WHERE foo.meet=mhs_meet_name AND 
                       foo.team=mhs_school_id) ;    

    END; $$ --end function
LANGUAGE 'plpgsql';



-- Question 4
CREATE OR REPLACE FUNCTION SchoolMeet2(sm_orgName VARCHAR(150),
	                                      sm_meetName VARCHAR(200))
RETURNS TABLE(participant_name  VARCHAR(50)) AS
$$
BEGIN
RETURN QUERY

 	       (SELECT DISTINCT swimmer as participant_name FROM MakeHeatSheetFull1() WHERE
 	              sm_orgName=team AND sm_meetName=meet AND is_relay=FALSE) ;

END
;$$
LANGUAGE 'plpgsql';






CREATE OR REPLACE FUNCTION MakeHeatSheetSchoolMeet2(
	                     mhs_school_id VARCHAR(20), 
	                     mhs_meet_name VARCHAR(200) )
    RETURNS TABLE(
  meet VARCHAR(200), event VARCHAR(20),  heat VARCHAR(20), swimmer VARCHAR(50),
  swimmer_id VARCHAR(20),
 team VARCHAR(150), race_time REAL, rank  BIGINT
)
AS 
$$ 
BEGIN
 RETURN QUERY (SELECT foo.meet, foo.event, foo.heat, foo.swimmer, 
 	foo.swimmer_id, foo.team, foo.race_time, foo.rank
 	       FROM (SELECT * FROM MakeHeatSheetFull1()) as foo
                WHERE foo.meet=mhs_meet_name AND 
                       foo.team=mhs_school_id) ;    

    END; $$ --end function
LANGUAGE 'plpgsql';


-- Question 4
CREATE OR REPLACE FUNCTION SchoolMeet(orgName VARCHAR(150),
                                      meetName VARCHAR(200))
    RETURNS TABLE(participant_name VARCHAR(50)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT DISTINCT Participant.name
            FROM Participant
            LEFT JOIN (SELECT swim_heat.heat_meet_name, swim_heat.participant_id, meet_org.meet_name, meet_org.Org_id, meet_org.org_name
                       FROM (SELECT Heat.meet_name AS heat_meet_name, Swim.participant_id
                             FROM Heat
                             LEFT JOIN Swim ON Swim.heat_id = Heat.id AND Swim.event_id = Heat.event_id AND Swim.meet_name = Heat.meet_name) AS swim_heat
                       LEFT JOIN (SELECT Meet.name AS meet_name, Org.id Org_id, Org.name AS org_name, Org.is_Univ
                                  FROM Meet
                                  LEFT JOIN Org ON Meet.org_id = Org.id) AS meet_org ON swim_heat.heat_meet_name = meet_org.meet_name) AS total_data ON Participant.id = total_data.participant_id
            WHERE total_data.org_name = orgName AND total_data.meet_name = meetName;
    END;$$
LANGUAGE 'plpgsql';

-- Question 5

CREATE OR REPLACE FUNCTION EventMeet(eventId VARCHAR(20),
                                     meetName VARCHAR(200))
    RETURNS TABLE(unit__Name VARCHAR(50),
				  heat__Id VARCHAR(20),
				  Event__Id VARCHAR(20),
				  meet__Name VARCHAR(200),
				  total__Time REAL,
				  event__Rank BIGINT) AS
$$
    BEGIN
        RETURN QUERY
			SELECT Org.name AS unit_name, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name, sum(time) AS total_time,
				   rank() OVER (PARTITION BY swim_participant.event_id ORDER BY sum(time)) AS event_rank
			FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, Participant.name AS parti_name
				  FROM Swim
				  LEFT JOIN Participant ON Swim.participant_id = Participant.id
				  WHERE event_id IN (SELECT DISTINCT event_id
						             FROM Swim
						             WHERE leg = 2)) AS swim_participant
			LEFT JOIN Org ON Org.id = swim_participant.org_id
			WHERE swim_participant.event_id = eventId AND swim_participant.meet_name = meetName
			GROUP BY Org.id, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name
			UNION ALL
			SELECT swim_participant.parti_name AS unit_name, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name, swim_participant.time AS total_time,
				   rank() OVER (PARTITION BY swim_participant.event_id ORDER BY time) AS event_rank
			FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, Participant.name AS parti_name
				  FROM Swim
				  LEFT JOIN Participant ON Swim.participant_id = Participant.id
				  WHERE event_id NOT IN (SELECT DISTINCT event_id
						                 FROM Swim
						                 WHERE leg = 2)) AS swim_participant
			LEFT JOIN Org ON Org.id = swim_participant.org_id
			WHERE swim_participant.event_id = eventId AND swim_participant.meet_name = meetName;
    END;$$
LANGUAGE 'plpgsql';

--Question6
CREATE OR REPLACE FUNCTION Meet(meetName VARCHAR(200))
    RETURNS TABLE(orgId VARCHAR(20),
				  totalScore INT) AS
$$
    BEGIN
        RETURN QUERY
			SELECT final_data2.org_id, Cast(Sum(score_sum) AS INT) AS total_score
			FROM (SELECT final_data.org_id, sum(relay_score) AS score_sum
				  FROM (SELECT total_data.org_id, 
						       CASE WHEN total_data.rank = 1 THEN 8
						       WHEN total_data.rank = 2 THEN 4
						       WHEN total_data.rank = 3 THEN 2
						       ELSE 0 END AS relay_score
						FROM (SELECT Org.id AS org_id, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name, sum(time) AS total_time,
						             rank() OVER (PARTITION BY swim_participant.event_id ORDER BY sum(time)) AS rank
						      FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, Participant.name AS parti_name
						            FROM Swim
						            LEFT JOIN Participant ON Swim.participant_id = Participant.id
						            WHERE event_id IN (SELECT DISTINCT event_id
						                               FROM Swim
						                               WHERE leg = 2)) AS swim_participant
						      LEFT JOIN Org ON Org.id = swim_participant.org_id
						      WHERE swim_participant.meet_name = 'SouthConfed'
						      GROUP BY Org.id, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name) AS total_data) AS final_data
				  GROUP BY org_id
				  UNION ALL
				  SELECT final_data.org_id, sum(score) AS score_sum
				  FROM (SELECT DISTINCT total_data.org_id, 
						                CASE WHEN rank = 1 THEN 6
						                     WHEN rank = 2 THEN 4
						                     WHEN rank = 3 THEN 3
						                     WHEN rank = 4 THEN 2
						                     WHEN rank = 5 THEN 1
						                     ELSE 0 END AS score
						FROM (SELECT swim_participant.org_id, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name, swim_participant.parti_name,swim_participant.time,
						             rank() OVER (PARTITION BY swim_participant.event_id ORDER BY time) AS rank
						      FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, Participant.name AS parti_name
						            FROM Swim
						            LEFT JOIN Participant ON Swim.participant_id = Participant.id
						            WHERE event_id NOT IN (SELECT DISTINCT event_id
						                                   FROM Swim
						                                   WHERE leg = 2)) AS swim_participant
						      LEFT JOIN Org ON Org.id = swim_participant.org_id
						      WHERE swim_participant.meet_name = 'SouthConfed') AS total_data) AS final_data 
				  GROUP BY final_data.org_id) AS final_data2
			GROUP BY final_data2.org_id
			ORDER BY total_score DESC;
    END;$$
LANGUAGE 'plpgsql';


--Question6
CREATE OR REPLACE FUNCTION Meet3(meetName VARCHAR(200))
    RETURNS TABLE(meet_Name VARCHAR(200),
				　　orgName VARCHAR(150),
				  orgId VARCHAR(20),
				  totalScore INT) AS
$$
    BEGIN
        RETURN QUERY
			SELECT final_data2.meet__name, final_data2.org_name, final_data2.org_id, Cast(sum(score_sum) AS INT) AS total_score
			FROM (SELECT final_data.meet__name, final_data.org_name, final_data.org_id, sum(relay_score) AS score_sum
      			  FROM (SELECT total_data.org_name, total_data.org_id, total_data.meet__name,
                  			   CASE WHEN total_data.rank = 1 THEN 8
			                        WHEN total_data.rank = 2 THEN 4
                 				    WHEN total_data.rank = 3 THEN 2
				                    ELSE 0 END AS relay_score
           		 	    FROM (SELECT Org.name AS org_name, Org.id AS org_id, swim_participant.meet_name AS meet__name,swim_participant.heat_id, swim_participant.event_id, 										 swim_participant.meet_name, sum(time) AS total_time,
                         			 rank() OVER (PARTITION BY swim_participant.event_id ORDER BY sum(time)) AS rank
			                  FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, 			Participant.name AS parti_name
			                        FROM Swim
			                        LEFT JOIN Participant ON Swim.participant_id = Participant.id
			                        WHERE event_id IN (SELECT DISTINCT event_id
			                                           FROM Swim
			                                           WHERE leg = 2)) AS swim_participant
			                  LEFT JOIN Org ON Org.id = swim_participant.org_id
			                  WHERE swim_participant.meet_name = 'SouthConfed'
			                  GROUP BY Org.id, swim_participant.heat_id, swim_participant.event_id, swim_participant.meet_name) AS total_data) AS final_data
		        GROUP BY org_id, final_data.org_name, final_data.meet__name
      		UNION ALL
		  		SELECT final_data.meet__name, final_data.org_name, final_data.org_id, sum(score) AS score_sum
		 		FROM (SELECT DISTINCT total_data.org_name, total_data.org_id, total_data.meet__name,
		        		                CASE WHEN rank = 1 THEN 6
		                   		             WHEN rank = 2 THEN 4
		                           		     WHEN rank = 3 THEN 3
				                             WHEN rank = 4 THEN 2
		    		                         WHEN rank = 5 THEN 1
		    		                         ELSE 0 END AS score
		   		       FROM (SELECT Org.name AS org_name, swim_participant.org_id, swim_participant.heat_id, swim_participant.meet_name AS meet__name, swim_participant.event_id, swim_participant.meet_name, swim_participant.parti_name,swim_participant.time,
		                     rank() OVER (PARTITION BY swim_participant.event_id ORDER BY time) AS rank
			                 FROM (SELECT Swim.heat_id, Swim.event_id, Swim.meet_name, Swim.time, Participant.org_id, Participant.name AS parti_name
		   		                   FROM Swim
		          		           LEFT JOIN Participant ON Swim.participant_id = Participant.id
		                 		   WHERE event_id NOT IN (SELECT DISTINCT event_id
		                 		                          FROM Swim
		                 		                          WHERE leg = 2)) AS swim_participant
			                 LEFT JOIN Org ON Org.id = swim_participant.org_id
		   		             WHERE swim_participant.meet_name = 'SouthConfed') AS total_data) AS final_data 
			  GROUP BY final_data.org_id, final_data.org_name, final_data.meet__name) AS final_data2
		GROUP BY final_data2.meet__name, final_data2.org_id, final_data2.org_name
		ORDER BY total_score DESC;
    END;$$
LANGUAGE 'plpgsql';


-------------------------------------------------------
--
-- Output Tables
--
-------------------------------------------------------

-- Org
CREATE OR REPLACE FUNCTION OutputOrg()
    RETURNS TABLE(id VARCHAR(20), 
                 name VARCHAR(150), 
                 is_univ BOOLEAN) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Org;
    END;$$
LANGUAGE 'plpgsql';

--Meet
CREATE OR REPLACE FUNCTION OutputMeet()
    RETURNS TABLE(name VARCHAR(200), 
				  start_date DATE, 
				  num_days INTEGER, 
				  org_id VARCHAR(20)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Meet;
    END;$$
LANGUAGE 'plpgsql';

--Participant
CREATE OR REPLACE FUNCTION OutputParticipant()
    RETURNS TABLE(id VARCHAR(20), 
	              name VARCHAR(50),
	              gender VARCHAR,
	              org_id VARCHAR(20)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Participant;
    END;$$
LANGUAGE 'plpgsql';

--Event
CREATE OR REPLACE FUNCTION OutputEvent()
    RETURNS TABLE(id VARCHAR(20), 
	           	  gender VARCHAR, 
	              distance INTEGER) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Event;
    END;$$
LANGUAGE 'plpgsql';

--Stroke
CREATE OR REPLACE FUNCTION OutputStroke()
    RETURNS TABLE(stroke VARCHAR(20)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Stroke;
    END;$$
LANGUAGE 'plpgsql';

--Distance
CREATE OR REPLACE FUNCTION OutputDistance()
    RETURNS TABLE(distance INTEGER) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Distance;
    END;$$
LANGUAGE 'plpgsql';

--Heat
CREATE OR REPLACE FUNCTION OutputHeat()
    RETURNS TABLE(id VARCHAR(20), 
	          	  event_id VARCHAR(20), 
	          	  meet_name VARCHAR(200)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Heat;
    END;$$
LANGUAGE 'plpgsql';

--Swim
CREATE OR REPLACE FUNCTION OutputSwim()
    RETURNS TABLE(heat_id VARCHAR(20), 
	          	  event_id VARCHAR(20), 
	          	  meet_name VARCHAR(200), 
	         	  participant_id VARCHAR(20), 
	         	  leg INT,match_time REAL) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Swim;
    END;$$
LANGUAGE 'plpgsql';

--Leg
CREATE OR REPLACE FUNCTION OutputLeg()
    RETURNS TABLE(leg INTEGER) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM Leg;
    END;$$
LANGUAGE 'plpgsql';

--StrokeOf
CREATE OR REPLACE FUNCTION OutputStrokeOf()
    RETURNS TABLE(event_id VARCHAR(20),
	              leg INTEGER,
	              stroke VARCHAR(20)) AS
$$
    BEGIN
        RETURN QUERY
            SELECT * FROM StrokeOf;
    END;$$
LANGUAGE 'plpgsql';




INSERT INTO  Remind Values
('Org', ' id, name, is_univ'),
('Leg', ' leg'),
('Meet', ' name, start_date, num_days, org_id'),
('Event', ' id, gender, distance'),
('Stroke', ' stroke'),
('StrokeOf', ': event_id, leg, stroke'),
('Participant', 'id, gender, org_id'),
('Distance', ' distance'),
('Heat', ' id, event_id, meet_name'),
('Swim', ' heat_id, event_id, meet_name, participant_id, leg, time')
;
INSERT INTO  RemindPrimaryKey Values
('Org', 'id'),
('Event', 'id'),
('Participant', 'id');
INSERT INTO  RemindNotPK Values
('Org', 'name, is_univ'),
('Event', 'gender, distance'),
('Participant', 'gender, org_id');
--


