-- --------------------------------------------------------------
-- Procedure for applying rules after a play
-- --------------------------------------------------------------

DROP PROCEDURE IF EXISTS Apply_Rules;
DELIMITER //
CREATE PROCEDURE Apply_Rules(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
     BEGIN
     -- All required variables
	DECLARE old_positionID_ INT; 
	DECLARE new_positionID_ INT; 
    DECLARE new_position_name_ VARCHAR(25);
    DECLARE PlayerID_ INT;
    DECLARE CurrentLocationName_ VARCHAR(25);
	DECLARE BoardLocationID_ INT;
    DECLARE PropertyName_ VARCHAR(25);
    DECLARE PropertyOwner_ INT;
    DECLARE PropertyCost_ INT;
	DECLARE PlayerBankBalance_ INT;
    DECLARE BonusID_ INT;
    DECLARE message VARCHAR (255);
    
    -- Set optional parameters
    SET Current_Board_Location = IFNULL(Current_Board_Location,0);
    SET PlayerName = IFNULL(PlayerName,0);
    SET Dice_Number = IFNULL(Dice_Number,0);
    
    -- Call the Player to roll the dice
    CALL LocationfromDiceRoll(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from rolling the dice to be used later
	SELECT old_positionID, new_positionID,new_position_name
	INTO old_positionID_,new_positionID_, new_position_name_
	FROM Store_Output;
    
    -- Setting current board location parameter that was NULL before to the new position name
    SET Current_Board_Location = new_position_name_;
        
    -- Call the procedure to deliver the player detail we will need later
	CALL PlayerDetails(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from player details to be used later
	SELECT PlayerID ,CurrentLocationName , BoardLocationID 
	INTO PlayerID_,CurrentLocationName_, BoardLocationID_
	FROM PlayerDetails;
    
        -- Call the procedure to deliver the table details we will need later
	CALL TableVariables(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from table details to be used later
	SELECT PropertyName ,PropertyOwner , PropertyCost, PlayerBankBalance , BonusID
	INTO PropertyName_,PropertyOwner_, PropertyCost_, PlayerBankBalance_ , BonusID_
	FROM TableVariables;
    SELECT * FROM TableVariables;
    
           -- SET CONDITIONS TO CALL THE RULES

##R1
    -- Rule 
	IF CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NULL
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    UPDATE Property
    SET Property.PlayerID = PlayerID_
    WHERE Property.PlayerID is NULL
    AND Property.PropertyName = Current_Board_Location;
    
    UPDATE Player
    SET Player.BankBalance = PlayerBankBalance_ - PropertyCost_ -- deduct player bank balance by property cost 
    WHERE Player.PlayerID = PlayerID_;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
       ##R2
    -- Rule
    IF 
	CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NOT NULL 
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    -- Create a table for properties with ownership
    DROP TABLE IF EXISTS Properties_Owned; 
    CREATE TABLE Properties_Owned (PropertyName VARCHAR(25),PlayerID INT,ColorName VARCHAR(25));
    
-- Populating Table (Properties_Owned)  
    INSERT INTO Properties_Owned
    SELECT Property.PropertyName,Property.PlayerID ,Property.ColorName
    FROM Property
    WHERE Property.PlayerID is NOT NULL;
    

-- Updating Player Ps account balance with conditions based on Property Ownership and Color
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance - (PropertyCost_ * 2)
	ELSE Player.BankBalance - PropertyCost_
    END
    WHERE Player.PlayerID = PlayerID_; 
        
-- Updating Player Qs account balance   
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance + (PropertyCost_ * 2)
	ELSE Player.BankBalance + PropertyCost_
    END
    WHERE Player.PlayerID = PropertyOwner_;
    
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    DROP TABLE Properties_Owned;
    END IF;
    
        #R4
     -- Rule
	IF old_positionID_ >= 11 AND old_positionID_ <= 16 
    AND new_positionID_ >= 1 AND new_positionID_ <= 6 THEN
    
    -- Action
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 200
    WHERE Player.PlayerID = PlayerID_ ;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
   	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;  
    
    SET message ='Player landed on or passed GO';
    SELECT message;
    
    END IF;
    
    #R6
    IF
    BoardLocationID_ = 13 
    THEN SET BoardLocationID_ = CASE WHEN old_positionID_ > BoardLocationID_ THEN old_positionID_ - (old_positionID_- 5) ELSE
    5 END;
    
    SET message = 'Player has been sent to Jail without passing GO';
    
	UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
    #R7
    IF Current_Board_Location = 'Chance 1' THEN
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 50
    WHERE Player.PlayerID != PlayerID_;
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 50
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    SET message = 'Norman has paid all players 50';
    SELECT message;

    ELSEIF Current_Board_Location = 'Chance 2' THEN
    
	SET BoardLocationID_ = CASE WHEN BoardLocationID_ + 3 > (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    THEN (BoardLocationID_ + 3) - (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    ELSE BoardLocationID_ + 3 END;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    ELSEIF Current_Board_Location = 'Community Chest 1' THEN   
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 100
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
	ELSEIF Current_Board_Location = 'Community Chest 2' THEN      
    
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 30
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
        
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    END IF;
    END//
DELIMITER ;


-- ----------------------------------------------------------------------------
-- Procedure to apply rules after geting a 6 while trying to get out of jail,
-- and playing the second roll 
-- ----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS Apply_Rules_Jail;
DELIMITER //
CREATE PROCEDURE Apply_Rules_Jail(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
     BEGIN
     -- All required variables
	DECLARE old_positionID_ INT; 
	DECLARE new_positionID_ INT; 
    DECLARE new_position_name_ VARCHAR(25);
    DECLARE PlayerID_ INT;
    DECLARE CurrentLocationName_ VARCHAR(25);
	DECLARE BoardLocationID_ INT;
    DECLARE PropertyName_ VARCHAR(25);
    DECLARE PropertyOwner_ INT;
    DECLARE PropertyCost_ INT;
	DECLARE PlayerBankBalance_ INT;
    DECLARE BonusID_ INT;
    DECLARE message VARCHAR (255);
    
    -- Set optional parameters
    SET Current_Board_Location = IFNULL(Current_Board_Location,0);
    SET PlayerName = IFNULL(PlayerName,0);
    SET Dice_Number = IFNULL(Dice_Number,0);
    
    -- Call the Player to roll the dice
    CALL SecondRollForJail(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from rolling the dice to be used later
	SELECT old_positionID, new_positionID,new_position_name
	INTO old_positionID_,new_positionID_, new_position_name_
	FROM Store_Output_InJail;
    
    -- Setting current board location parameter that was NULL before to the new position name
    SET Current_Board_Location = new_position_name_;
        
    -- Call the procedure to deliver the player detail we will need later
	CALL PlayerDetails(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from player details to be used later
	SELECT PlayerID ,CurrentLocationName , BoardLocationID 
	INTO PlayerID_,CurrentLocationName_, BoardLocationID_
	FROM PlayerDetails;
    
        -- Call the procedure to deliver the table details we will need later
	CALL TableVariables(Current_Board_Location,PlayerName,Dice_Number);
    
   -- Get the needed values from table details to be used later
	SELECT PropertyName ,PropertyOwner , PropertyCost, PlayerBankBalance , BonusID
	INTO PropertyName_,PropertyOwner_, PropertyCost_, PlayerBankBalance_ , BonusID_
	FROM TableVariables;
    SELECT * FROM TableVariables;
    
          -- SET CONDITIONS TO CALL THE RULES

##R1
    -- Rule 
	IF CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NULL
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    UPDATE Property
    SET Property.PlayerID = PlayerID_
    WHERE Property.PlayerID is NULL
    AND Property.PropertyName = Current_Board_Location;
    
    UPDATE Player
    SET Player.BankBalance = PlayerBankBalance_ - PropertyCost_ -- deduct player bank balance by property cost 
    WHERE Player.PlayerID = PlayerID_;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
       ##R2
    -- Rule
    IF 
	CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NOT NULL 
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    -- Create a table for properties with ownership
    DROP TABLE IF EXISTS Properties_Owned; 
    CREATE TABLE Properties_Owned (PropertyName VARCHAR(25),PlayerID INT,ColorName VARCHAR(25));
    
-- Populating Table (Properties_Owned)  
    INSERT INTO Properties_Owned
    SELECT Property.PropertyName,Property.PlayerID ,Property.ColorName
    FROM Property
    WHERE Property.PlayerID is NOT NULL;
    

-- Updating Player Ps account balance with conditions based on Property Ownership and Color
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance - (PropertyCost_ * 2)
	ELSE Player.BankBalance - PropertyCost_
    END
    WHERE Player.PlayerID = PlayerID_; 
        
-- Updating Player Qs account balance   
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance + (PropertyCost_ * 2)
	ELSE Player.BankBalance + PropertyCost_
    END
    WHERE Player.PlayerID = PropertyOwner_;
    
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    DROP TABLE Properties_Owned;
    END IF;
    
        #R4
     -- Rule
	IF old_positionID_ >= 11 AND old_positionID_ <= 16 
    AND new_positionID_ >= 1 AND new_positionID_ <= 6 THEN
    
    -- Action
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 200
    WHERE Player.PlayerID = PlayerID_ ;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
   	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;  
    
    SET message ='Player landed on or passed GO';
    SELECT message;
    
    END IF;
    
    #R6
    IF
    BoardLocationID_ = 13 
    THEN SET BoardLocationID_ = CASE WHEN old_positionID_ > BoardLocationID_ THEN old_positionID_ - (old_positionID_- 5) ELSE
    5 END;
    
    SET message = 'Player has been sent to Jail without passing GO';
    
	UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
    #R7
    IF Current_Board_Location = 'Chance 1' THEN
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 50
    WHERE Player.PlayerID != PlayerID_;
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 50
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    SET message = 'Norman has paid all players 50';
    SELECT message;

    ELSEIF Current_Board_Location = 'Chance 2' THEN
    
	SET BoardLocationID_ = CASE WHEN BoardLocationID_ + 3 > (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    THEN (BoardLocationID_ + 3) - (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    ELSE BoardLocationID_ + 3 END;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    ELSEIF Current_Board_Location = 'Community Chest 1' THEN   
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 100
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
	ELSEIF Current_Board_Location = 'Community Chest 2' THEN      
    
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 30
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
        
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    END IF;
    END//
DELIMITER ;


-- ---------------------------------------------------------------------
-- Procedure to apply rules after geting a 6 and playing the second roll
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS Apply_Rules_SecondRoll;
DELIMITER //
CREATE PROCEDURE Apply_Rules_SecondRoll(Current_Board_Location VARCHAR(25),
     PlayerName VARCHAR(25), Dice_Number INT)
     BEGIN
     -- All required variables
	DECLARE old_positionID_ INT; 
	DECLARE new_positionID_ INT; 
    DECLARE new_position_name_ VARCHAR(25);
    DECLARE PlayerID_ INT;
    DECLARE CurrentLocationName_ VARCHAR(25);
	DECLARE BoardLocationID_ INT;
    DECLARE PropertyName_ VARCHAR(25);
    DECLARE PropertyOwner_ INT;
    DECLARE PropertyCost_ INT;
	DECLARE PlayerBankBalance_ INT;
    DECLARE BonusID_ INT;
    DECLARE message VARCHAR (255);
    
    -- Set optional parameters
    SET Current_Board_Location = IFNULL(Current_Board_Location,0);
    SET PlayerName = IFNULL(PlayerName,0);
    SET Dice_Number = IFNULL(Dice_Number,0);
    
    -- Call the Player to roll the dice
    CALL SecondRoll(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from rolling the dice to be used later
	SELECT old_positionID, new_positionID,new_position_name
	INTO old_positionID_,new_positionID_, new_position_name_
	FROM Store_Output_SecondRoll;
    
    -- Setting current board location parameter that was NULL before to the new position name
    SET Current_Board_Location = new_position_name_;
        
    -- Call the procedure to deliver the player detail we will need later
	CALL PlayerDetails(Current_Board_Location,PlayerName,Dice_Number);
    
    -- Get the needed values from player details to be used later
	SELECT PlayerID ,CurrentLocationName , BoardLocationID 
	INTO PlayerID_,CurrentLocationName_, BoardLocationID_
	FROM PlayerDetails;
    
        -- Call the procedure to deliver the table details we will need later
	CALL TableVariables(Current_Board_Location,PlayerName,Dice_Number);
    
  -- Get the needed values from table details to be used later
	SELECT PropertyName ,PropertyOwner , PropertyCost, PlayerBankBalance , BonusID
	INTO PropertyName_,PropertyOwner_, PropertyCost_, PlayerBankBalance_ , BonusID_
	FROM TableVariables;
    SELECT * FROM TableVariables;
    
          -- SET CONDITIONS TO CALL THE RULES

##R1
    -- Rule 
	IF CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NULL
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    UPDATE Property
    SET Property.PlayerID = PlayerID_
    WHERE Property.PlayerID is NULL
    AND Property.PropertyName = Current_Board_Location;
    
    UPDATE Player
    SET Player.BankBalance = PlayerBankBalance_ - PropertyCost_ -- deduct player bank balance by property cost 
    WHERE Player.PlayerID = PlayerID_;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
       ##R2
    -- Rule
    IF 
	CurrentLocationName_ = 'Property' 
    AND PropertyOwner_ is NOT NULL 
    AND Current_Board_Location = PropertyName_
    THEN
    -- Action
    -- Create a table for properties with ownership
    DROP TABLE IF EXISTS Properties_Owned; 
    CREATE TABLE Properties_Owned (PropertyName VARCHAR(25),PlayerID INT,ColorName VARCHAR(25));
    
-- Populating Table (Properties_Owned)  
    INSERT INTO Properties_Owned
    SELECT Property.PropertyName,Property.PlayerID ,Property.ColorName
    FROM Property
    WHERE Property.PlayerID is NOT NULL;
    

-- Updating Player Ps account balance with conditions based on Property Ownership and Color
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance - (PropertyCost_ * 2)
	ELSE Player.BankBalance - PropertyCost_
    END
    WHERE Player.PlayerID = PlayerID_; 
        
-- Updating Player Qs account balance   
	UPDATE Player 
    INNER JOIN Properties_Owned ON Player.PlayerID = Properties_Owned.PlayerID
	SET Player.BankBalance = CASE WHEN Current_Board_Location = (SELECT PropertyName FROM Properties_Owned AS A
	WHERE EXISTS
	(SELECT  1
	FROM Properties_Owned AS B
	WHERE B.ColorName = A.ColorName AND A.PlayerID = PropertyOwner_ AND A.PropertyName = Current_Board_Location
	LIMIT 1, 1))
	THEN Player.BankBalance + (PropertyCost_ * 2)
	ELSE Player.BankBalance + PropertyCost_
    END
    WHERE Player.PlayerID = PropertyOwner_;
    
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    DROP TABLE Properties_Owned;
    END IF;
    
        #R4
     -- Rule
	IF old_positionID_ >= 11 AND old_positionID_ <= 16 
    AND new_positionID_ >= 1 AND new_positionID_ <= 6 THEN
    
    -- Action
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 200
    WHERE Player.PlayerID = PlayerID_ ;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
   	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;  
    
    SET message ='Player landed on or passed GO';
    SELECT message;
    
    END IF;
    
    #R6
    IF
    BoardLocationID_ = 13 
    THEN SET BoardLocationID_ = CASE WHEN old_positionID_ > BoardLocationID_ THEN old_positionID_ - (old_positionID_- 5) ELSE
    5 END;
    
    SET message = 'Player has been sent to Jail without passing GO';
    
	UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_; 
    END IF;
    
    #R7
    IF Current_Board_Location = 'Chance 1' THEN
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 50
    WHERE Player.PlayerID != PlayerID_;
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 50
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    SET message = 'Norman has paid all players 50';
    SELECT message;

    ELSEIF Current_Board_Location = 'Chance 2' THEN
    
	SET BoardLocationID_ = CASE WHEN BoardLocationID_ + 3 > (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    THEN (BoardLocationID_ + 3) - (SELECT max(Board_Location.Board_LocationID) FROM Board_Location)
    ELSE BoardLocationID_ + 3 END;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    ELSEIF Current_Board_Location = 'Community Chest 1' THEN   
    
	UPDATE Player
    SET Player.BankBalance = Player.BankBalance + 100
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
    
	UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
	ELSEIF Current_Board_Location = 'Community Chest 2' THEN      
    
    UPDATE Player
    SET Player.BankBalance = Player.BankBalance - 30
    WHERE Player.PlayerID = PlayerID_;
    
    UPDATE Player
    SET Player.BonusID = BonusID_
    WHERE Player.PlayerID = PlayerID_ ;
        
    UPDATE Player
    SET Player.CurrentLocationID = BoardLocationID_
    WHERE Player.PlayerID = PlayerID_;
    
    END IF;
    END//
DELIMITER ;