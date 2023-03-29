-- ----------------------
-- Insert into Player Table
-- ----------------------
SET FOREIGN_KEY_CHECKS=0;
INSERT INTO Player
VALUES 
(1,'Mary',190,9,'Battleship','5'),
(2,'Bill',500,12,'Dog',NULL),
(3,'Jane',150,14,'Car',NULL),
(4,'Norman',250,2,'Thimble',NULL);
#4 Values

-- ----------------------
-- Insert into Property Table
-- ----------------------

INSERT INTO Property
VALUES 
('Oak House',100,'Orange','Property',4),
('Owens Park',30,'Orange','Property',4),
('AMBS',400,'Blue','Property',NULL),
('Co-Op',30,'Blue','Property',3),
('Kilburn',120,'Yellow','Property',NULL),
('Uni Place',100,'Yellow','Property',1),
('Victoria',75,'Green','Property',2),
('Piccadilly',35,'Green','Property',NULL);
#8 Values

-- ----------------------
-- Insert into Bonus Table
-- ----------------------

INSERT INTO Bonus
VALUES 
(1,'Chance 1','Pay each of the other players £50','Chance'),
(2,'Chance 2','Move forward 3 spaces','Chance'),
(3,'Community Chest 1','For winning a Beauty Contest, you win £100','Community Chest'),
(4,'Community Chest 2','Your library books are overdue. Play a fine of £30','Community Chest'),
(5,'Free Parking','No action','Corner'),
(6,'Go to Jail','Go to Jail, do not pass GO, do not collect £200','Corner'),
(7,'GO','Collect £200','Corner'),
(8,'In Jail','Roll a 6 to get out','Corner');
#8 Values

-- ----------------------
-- Insert into Token Table
-- ----------------------

INSERT INTO Token
VALUES 
('Dog'),
('Car'),
('Battleship'),
('Top hat'),
('Thimble'),
('Boot');
#6 Values

-- ----------------------
-- Insert into Location Table
-- ----------------------

INSERT INTO Location
VALUES 
('Corner'),
('Chance'),
('Community Chest'),
('Property');
#4 Values

-- ----------------------
-- Insert into Color Table
-- ----------------------

INSERT INTO Color
VALUES 
('Orange'),
('Blue'),
('Yellow'),
('Green');
#4 Values


-- ----------------------
-- Insert into Board_Location Table
-- ----------------------

INSERT INTO Board_Location
VALUES 
(1,'GO','Corner'),
(2,'Kilburn','Property'),
(3,'Chance 1','Chance'),
(4,'Uni Place','Property'),
(5,'In Jail','Corner'),
(6,'Victoria','Property'),
(7,'Community Chest 1','Community Chest'),
(8,'Piccadilly','Property'),
(9,'Free Parking','Corner'),
(10,'Oak House','Property'),
(11,'Chance 2','Chance'),
(12,'Owens Park','Property'),
(13,'Go to Jail','Corner'),
(14,'AMBS','Property'),
(15,'Community Chest 2','Community Chest'),
(16,'Co-Op','Property')
; 
-- 16 Values


-- For the Audit Trail Table
-- a trigger was created to automatically insert into it once there’s an update to the player table(implying that the player has taken a turn) 

-- -----------------------------------------------------------------------
-- CREATE TRIGGER TO INSERT INTO Audit Trail AFTER UPDATE ON Player table
-- -----------------------------------------------------------------------

DROP TRIGGER IF EXISTS InsertintoAuditTrail;
DELIMITER //
 CREATE TRIGGER InsertintoAuditTrail
 AFTER UPDATE ON Player
 FOR EACH ROW
 BEGIN
 IF OLD.CurrentLocationID <> NEW.CurrentLocationID THEN 
 INSERT INTO Audit_Trail(PlayerID,PlayerName,CurrentPosition, PlayerBankBalance, PlayerTurn, GameRound)
 VALUES(OLD.PlayerID, OLD.PlayerName, (SELECT Board_LocationName 
									  FROM Board_Location 
                                      WHERE NEW.CurrentLocationID = Board_Location.Board_LocationID), NEW.BankBalance, PlayerTurn, GameRound);
 END IF;
  END//