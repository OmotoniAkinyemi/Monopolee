-- --------------------------------------------------------------
-- Get the location of the player after making a play
-- --------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE LocationfromDiceRoll(
    -- IN CurrentLocation VARCHAR(25),
    PlayerName VARCHAR(25),Dice_Number INT)
    
     BEGIN
    DECLARE old_position INT; 
    DECLARE new_position INT;
    -- DECLARE new_position_name VARCHAR(255);
	DECLARE message VARCHAR(255);
    
    SELECT Player.CurrentLocationID
    INTO old_position
    FROM Player
    WHERE PlayerName = Player.PlayerName;
    
    
    IF Dice_Number < 6 THEN
    SET new_position = CASE WHEN old_position + Dice_Number > (SELECT max(Player.CurrentLocationID) FROM Player)
    THEN (old_position + Dice_Number) - (SELECT max(Player.CurrentLocationID) FROM Player)
    ELSE old_position + Dice_Number END;
    
     /* SELECT Board_Location.Board_LocationName
    INTO new_position_name
    FROM Board_Location
    WHERE new_position = Board_Location.Board_LocationID; */
    
    -- SELECT new_position_name;
    
	ELSE SET new_position = CASE WHEN old_position + Dice_Number > (SELECT max(Player.CurrentLocationID) FROM Player)
    THEN (old_position + Dice_Number) - (SELECT max(Player.CurrentLocationID) FROM Player) 
    ELSE old_position + Dice_Number END;
    SET message = 'Yay! Roll Again';
	SELECT message;
    
	END IF;
    
END //

DELIMITER ;


-- -----------------------------------------------------
-- What to do if Player winds up in Jail
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS ActionifInJail; 
DELIMITER //
CREATE PROCEDURE ActionifInJail(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
BEGIN
DECLARE old_position INT;
DECLARE new_position INT;
DECLARE message VARCHAR (255);


SET Current_Board_Location = IFNULL(Current_Board_Location,0);
 

CALL LocationfromDiceRoll(Current_Board_Location,PlayerName,Dice_Number);

SELECT old_positionID
INTO old_position
FROM Save_Jail_Status;
    
IF old_position = 5 THEN
SET new_position = NULL;
END IF;

IF old_position = 5 AND Dice_Number = 6 THEN
SET new_position = old_position;
SELECT old_position,new_position;
SET message = "You are out of jail. Roll again!";
SELECT message;

    -- Store the ouput of the dice roll in a temporary table
	DROP TABLE IF EXISTS Store_ActionifInJail;
    CREATE TEMPORARY TABLE Store_ActionifInJail (old_positionID INT,new_positionID INT);
    INSERT INTO Store_ActionifInJail
    VALUES(old_position,new_position);

ELSE
SET message = 'Sorry! You need to roll a 6 to get out of Jail';
SELECT message;
END IF;
END//
DELIMITER ;

-- -----------------------------------------------------
-- Use this procedure if the Player lands a '6'
-- -----------------------------------------------------

DROP PROCEDURE IF EXISTS SecondRoll; 
DELIMITER //
CREATE PROCEDURE SecondRoll(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
BEGIN
DECLARE old_position INT;
DECLARE new_position INT;
DECLARE new_position_name VARCHAR(25);
DECLARE message VARCHAR (255);


 SET Current_Board_Location = IFNULL(Current_Board_Location,0);
 

CALL LocationfromDiceRoll(Current_Board_Location,PlayerName,Dice_Number);

SELECT old_positionID, new_positionID
INTO old_position, new_position
FROM Store_Output_2;
SELECT old_position ;
SELECT new_position ;
    
    SET old_position = new_position;
    
    SET new_position = CASE WHEN old_position + Dice_Number > (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
	THEN (old_position + Dice_Number) - (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
	ELSE old_position + Dice_Number END;
    
    	-- get new position name from Board Location Table
					SELECT Board_Location.Board_LocationName
					INTO new_position_name
					FROM Board_Location
					WHERE new_position = Board_Location.Board_LocationID;
                    
				SET message = CONCAT('The new Board Location for ', PlayerName, ' is ', new_position_name);
				-- SELECT message;

  -- Store the ouput of the second dice roll in a temporary table
	DROP TABLE IF EXISTS Store_Output_SecondRoll;
    CREATE TEMPORARY TABLE Store_Output_SecondRoll (old_positionID INT,new_positionID INT, message VARCHAR(255), new_position_name VARCHAR(25));
    INSERT INTO Store_Output_SecondRoll
    VALUES(old_position,new_position,message, new_position_name);
    SELECT message,new_position_name,old_position FROM Store_Output_SecondRoll;
END//
DELIMITER ;



-- ---------------------------------------------------------------------------
-- Use this procedure if the Player lands a '6' while trying to get out of jail
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS SecondRollForJail; 
DELIMITER //
CREATE PROCEDURE SecondRollForJail(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
BEGIN
DECLARE old_position INT;
DECLARE new_position INT;
DECLARE new_position_name VARCHAR(25);
DECLARE message VARCHAR (255);


 SET Current_Board_Location = IFNULL(Current_Board_Location,0);
 

CALL ActionifInJail(Current_Board_Location,PlayerName,Dice_Number);

SELECT old_positionID, new_positionID
INTO old_position, new_position
FROM Store_ActionifInJail;
    
IF old_position = new_position THEN
SET new_position = CASE WHEN old_position + Dice_Number > (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
	THEN (old_position + Dice_Number) - (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
	ELSE old_position + Dice_Number END;
    
    	-- get new position name from Board Location Table
					SELECT Board_Location.Board_LocationName
					INTO new_position_name
					FROM Board_Location
					WHERE new_position = Board_Location.Board_LocationID;
                    
				SET message = CONCAT('The new Board Location for ', PlayerName, ' is ', new_position_name);
				-- SELECT message;
END IF;
  -- Store the ouput of the second dice roll in a temporary table
	DROP TABLE IF EXISTS Store_Output_InJail;
    CREATE TEMPORARY TABLE Store_Output_InJail (old_positionID INT,new_positionID INT, message VARCHAR(255), new_position_name VARCHAR(25));
    INSERT INTO Store_Output_InJail
    VALUES(old_position,new_position,message, new_position_name);
    SELECT message,new_position_name,old_position FROM Store_Output_InJail;
END//
DELIMITER ;

