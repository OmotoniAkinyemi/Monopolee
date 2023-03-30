-- ---------------------------------------------------
-- Create Procedure for retrieving the PlayerID
-- ---------------------------------------------------
DROP PROCEDURE IF EXISTS getPlayerID ;
DELIMITER //
CREATE PROCEDURE getPlayerID( Current_Board_Location VARCHAR(25), 
    PlayerName VARCHAR(25),Dice_Number INT )
BEGIN
DECLARE PlayerID INT;
SET Current_Board_Location = IFNULL(Current_Board_Location,0);
SET Dice_Number = IFNULL(Dice_Number,0);
	SELECT Player.PlayerID
	INTO PlayerID
	FROM Player
	WHERE PlayerName = Player.PlayerName;
END //
DELIMITER ;

-- ---------------------------------------------------
-- Create Procedure for retrieving the Location Name
-- ---------------------------------------------------
DROP PROCEDURE IF EXISTS getLocationName ;
DELIMITER //
CREATE PROCEDURE getLocationName( Current_Board_Location VARCHAR(25), 
    PlayerName VARCHAR(25),Dice_Number INT)
BEGIN
DECLARE CurrentLocationName VARCHAR(25);
SET PlayerName = IFNULL(PlayerName,0);
SET Dice_Number = IFNULL(Dice_Number,0);
    SELECT Board_Location.Location_Name
    INTO CurrentLocationName
    FROM Board_Location
    WHERE Board_Location.Board_LocationName = Current_Board_Location;
END //
DELIMITER ;
    
    
-- ------------------------------------------------------
-- Create Procedure for retrieving the Board Location ID
-- ------------------------------------------------------
DROP PROCEDURE IF EXISTS getBoardLocationID ;
DELIMITER //
CREATE PROCEDURE getBoardLocationID( Current_Board_Location VARCHAR(25), 
    PlayerName VARCHAR(25),Dice_Number INT)
BEGIN
DECLARE BoardLocationID INT;
SET PlayerName = IFNULL(PlayerName,0);
SET Dice_Number = IFNULL(Dice_Number,0);
	SELECT Board_Location.Board_LocationID
    INTO BoardLocationID
    FROM Board_Location
    WHERE Current_Board_Location = Board_Location.Board_LocationName;
END //
DELIMITER ;


-- ------------------------------------------------------
-- Create Procedure for Updating Player Location
-- ------------------------------------------------------
DROP PROCEDURE IF EXISTS updatePlayerLocation ;
DELIMITER //
CREATE PROCEDURE updatePlayerLocation(Current_Board_Location VARCHAR(25), 
    PlayerName VARCHAR(25), Dice_Number INT)
BEGIN
SET PlayerName = IFNULL(PlayerName,0);
SET Dice_Number = IFNULL(Dice_Number,0);
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID
    WHERE PlayerID = Player.PlayerID; 
END //
DELIMITER ;

-- ------------------------------------------------------
-- Create Procedure for getting Player Initial Location
-- ------------------------------------------------------
DROP PROCEDURE IF EXISTS getPlayerLocation ;
DELIMITER //
CREATE PROCEDURE getPlayerLocation( Current_Board_Location VARCHAR(25),PlayerName VARCHAR(25),Dice_Number INT)
BEGIN
DECLARE old_positionID INT;
SET Current_Board_Location = IFNULL(Current_Board_Location,0);
SET Dice_Number = IFNULL(Dice_Number,0);
	SELECT Player.CurrentLocationID
    INTO old_positionID
    FROM Player
    WHERE PlayerName = Player.PlayerName;
END//

DELIMITER ;


-- ------------------------------------------------------
-- Create Procedure for getting Player Details
-- ------------------------------------------------------

DROP PROCEDURE IF EXISTS PlayerDetails ;
DELIMITER //
CREATE PROCEDURE PlayerDetails( Current_Board_Location VARCHAR(25),PlayerName VARCHAR(25),Dice_Number INT)
BEGIN
DECLARE PlayerID INT;
DECLARE CurrentLocationName VARCHAR(25);
DECLARE BoardLocationID INT;
SET Dice_Number = IFNULL(Dice_Number,0);

SELECT Player.PlayerID
	INTO PlayerID
	FROM Player
	WHERE PlayerName = Player.PlayerName;

SELECT Board_Location.LocationName
    INTO CurrentLocationName
    FROM Board_Location
    WHERE Board_Location.Board_LocationName = Current_Board_Location;
    
SELECT Board_Location.Board_LocationID
    INTO BoardLocationID
    FROM Board_Location
    WHERE Current_Board_Location = Board_Location.Board_LocationName;
    
    -- Store the ouput of the Player Details in a temporary table
	DROP TABLE IF EXISTS PlayerDetails;
    CREATE TEMPORARY TABLE PlayerDetails (PlayerID INT,CurrentLocationName VARCHAR(25), BoardLocationID INT);
    INSERT INTO PlayerDetails
    VALUES(PlayerID,CurrentLocationName,BoardLocationID);

END//

DELIMITER ;


-- ------------------------------------------------------
-- Create Procedure for getting Table Variables
-- ------------------------------------------------------

DROP PROCEDURE IF EXISTS TableVariables ;
DELIMITER //
CREATE PROCEDURE TableVariables( Current_Board_Location VARCHAR(25),PlayerName VARCHAR(25),Dice_Number INT)
BEGIN
DECLARE PropertyName VARCHAR(25);
DECLARE PropertyOwner INT;
DECLARE PropertyCost INT;
DECLARE PlayerBankBalance INT;
DECLARE BonusID INT;

SET Dice_Number = IFNULL(Dice_Number,0);

  SELECT Property.PropertyName
   INTO PropertyName
   FROM Property
   WHERE Current_Board_Location = Property.PropertyName;
   
	SELECT Property.PlayerID
   INTO PropertyOwner
   FROM Property
   WHERE Current_Board_Location = Property.PropertyName;
   
   	SELECT Property.PurchaseCost
   INTO PropertyCost
   FROM Property
   WHERE Current_Board_Location = Property.PropertyName;
   
   	SELECT Player.BankBalance
   INTO PlayerBankBalance
   FROM Player
   WHERE PlayerName = Player.PlayerName;
   
	SELECT Bonus.BonusID
   INTO BonusID
   FROM Bonus
   WHERE Current_Board_Location = Bonus.BonusName;
   
       -- Store the ouput of the Table Details in a temporary table
	DROP TABLE IF EXISTS TableVariables;
    CREATE TEMPORARY TABLE TableVariables (PropertyName VARCHAR(25),PropertyOwner INT, PropertyCost INT,PlayerBankBalance INT, BonusID INT);
    INSERT INTO TableVariables
    VALUES(PropertyName,PropertyOwner,PropertyCost,PlayerBankBalance,BonusID);


END//

DELIMITER ;
