SET FOREIGN_KEY_CHECKS=1;

-- -----------------------------
-- Create Table 'Player'
-- -----------------------------
DROP TABLE IF EXISTS `Player`;
CREATE TABLE `Player` (
    `PlayerID` INT NOT NULL AUTO_INCREMENT,
    `PlayerName` VARCHAR(25) NULL DEFAULT NULL,
    `BankBalance` INT NULL DEFAULT NULL,
    `CurrentLocationID` INT NOT NULL,
    `ChosenToken` VARCHAR(25) NOT NULL,
    `BonusID` INT NULL DEFAULT NULL,
    PRIMARY KEY (`PlayerID`),
    FOREIGN KEY (`CurrentLocationID`)
        REFERENCES `Board_Location` (`Board_LocationID`),
    FOREIGN KEY (`ChosenToken`)
        REFERENCES `Token` (`TokenName`),
    FOREIGN KEY (`BonusID`)
        REFERENCES `Bonus` (`BonusID`)
);
        
-- -----------------------------
-- Create Table 'Bonus'
-- -----------------------------        

DROP TABLE IF EXISTS `Bonus`;
CREATE TABLE `Bonus` (
    `BonusID` INT NOT NULL AUTO_INCREMENT,
    `BonusName` VARCHAR(25) NULL DEFAULT NULL,
    `BonusDescription` LONGTEXT NULL DEFAULT NULL,
    `LocationName` VARCHAR(25) NOT NULL,
    PRIMARY KEY (`BonusID`),
    FOREIGN KEY (`LocationName`)
        REFERENCES `Location` (`LocationName`)
);
        
        
-- -----------------------------
-- Create Table 'Property'
-- ----------------------------- 

DROP TABLE IF EXISTS `Property`;
CREATE TABLE `Property` (
    `PropertyName` VARCHAR(25) NOT NULL,
    `PurchaseCost` INT NOT NULL,
    `ColorName` VARCHAR(25) NULL DEFAULT NULL,
    `LocationName` VARCHAR(25) NOT NULL,
    `PlayerID` INT NULL DEFAULT NULL ,
    PRIMARY KEY (`PropertyName`),
    FOREIGN KEY (`ColorName`)
        REFERENCES `Color` (`ColorName`),
	FOREIGN KEY (`LocationName`)
        REFERENCES `Location` (`LocationName`),
	FOREIGN KEY (`PlayerID`)
        REFERENCES `Player` (`PlayerID`)
);
        
        
-- -----------------------------
-- Create Table 'Location'
-- ----------------------------- 

DROP TABLE IF EXISTS `Location`;
CREATE TABLE `Location` (
    `LocationName` VARCHAR(25) NOT NULL ,
    PRIMARY KEY (`LocationName`)
);


-- -----------------------------
-- Create Table 'Token'
-- ----------------------------- 

DROP TABLE IF EXISTS `Token`;
CREATE TABLE `Token` (
    `TokenName` VARCHAR(25) NOT NULL,
    PRIMARY KEY (`TokenName`)
);

-- -----------------------------
-- Create Table 'Color'
-- ----------------------------- 

DROP TABLE IF EXISTS `Color`;
CREATE TABLE `Color` (
    `ColorName` VARCHAR(25) NOT NULL ,
    PRIMARY KEY (`ColorName`)
);

-- -----------------------------
-- Create Table 'BoardLocation'
-- ----------------------------- 

DROP TABLE IF EXISTS `Board_Location`; 
CREATE TABLE `Board_Location` (
    `Board_LocationID` INT NOT NULL,
    `Board_LocationName` VARCHAR(25) NULL DEFAULT NULL,
    `LocationName` VARCHAR(25) NOT NULL,
    PRIMARY KEY (`Board_LocationID`),
    FOREIGN KEY (`LocationName`)
        REFERENCES `Location` (`LocationName`)
);