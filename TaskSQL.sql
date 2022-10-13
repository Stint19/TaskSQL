DROP TABLE Social_statuses_register;
GO
DROP TABLE Branches;
GO
DROP TABLE Cards;
GO
DROP TABLE Accounts;
GO
DROP TABLE Clients;
GO
DROP TABLE Social_statuses;
GO
DROP TABLE Banks;
GO
DROP TABLE Cities;
GO
DROP PROCEDURE AddBalance
GO
DROP PROCEDURE SendToCard
GO


CREATE TABLE Cities
(
	Id INT PRIMARY KEY IDENTITY,
	City_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE Banks
(
	Id INT PRIMARY KEY IDENTITY,
	Bank_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE Social_statuses
(
	Id INT PRIMARY KEY IDENTITY,
	Status_name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE Clients
(
	Id INT PRIMARY KEY IDENTITY,
	Client_name VARCHAR(20) NOT NULL
);

CREATE TABLE Social_statuses_register
(
	Client_id INT REFERENCES Clients(id),
	Social_status_id INT REFERENCES Social_statuses(Id)
);

CREATE TABLE Accounts
(
	Id INT PRIMARY KEY IDENTITY,
	Bank_id INT REFERENCES Banks(Id),
	Client_id INT REFERENCES Clients(Id),
	Balance MONEY NOT NULL
);

CREATE TABLE Cards
(
	Id INT PRIMARY KEY IDENTITY,
	Account_id INT REFERENCES Accounts(Id) NOT NULL,
	Balance MONEY NOT NULL,
);


CREATE TABLE Branches
(
	Id INT PRIMARY KEY IDENTITY,
	Bank_id INT REFERENCES Banks(Id),
	City_id INT REFERENCES Cities(Id),
	Adress VARCHAR(30) NOT NULL,
);
GO

ALTER TABLE Accounts
  ADD CONSTRAINT account_unique UNIQUE (Bank_id, Client_id);
GO

ALTER TABLE Social_statuses_register
  ADD CONSTRAINT soc_status_unique UNIQUE (Client_id, Social_status_id);
GO

INSERT INTO Cities 
VALUES
('Gomel'),
('Minsk'),
('Brest'),
('Grodno'),
('Mogilev')
GO

INSERT INTO Banks
VALUES
('Belarusbank'),
('Priorbank'),
('Sberbank'),
('Tinkoff Bank'),
('BelVeb Bank')
GO

INSERT INTO Social_statuses
VALUES
('Пенсионер'),
('Инвалид'),
('Безработный'),
('Студент'),
('Работающий')
GO

INSERT INTO Clients
VALUES
('Вася'),
('Петя'),
('Вова'),
('Никита'),
('Миша1'),
('Степан1'),
('Миша2'),
('Степан2')

INSERT INTO Social_statuses_register
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 4),
(6, 4),
(7, 3),
(8, 2),
(6, 2),
(5, 1),
(3, 4)

INSERT INTO Branches
VALUES
(1,5,'ул. Советская 6'),
(2,4,'ул. Пушкина 5'),
(3,3,'ул. Северная 5'),
(4,2,'ул. Хатаевича 33'),
(1,1,'ул. Московская 2а'),
(3,2,'ул. Свиридова 18'),
(1,4,'ул. Крестьянская 2'),
(5,1,'Проспект победителей 23')
GO

INSERT INTO Accounts
VALUES
(1,1,1000),
(2,8,1000),
(3,7,5000),
(4,3,3000),
(5,2,4000),
(4,2,2000),
(3,4,1200),
(2,7,3000),
(5,8,4000),
(3,5,4030)
GO

INSERT INTO Cards
VALUES
(1,100),
(2,200),
(3,300),
(4,400),
(5,500),
(6,600),
(6,100),
(6,100),
(3,400),
(8,600),
(2,400),
(9,300)
GO

/*TASK 1*/
SELECT DISTINCT Bank_name
FROM Cities
	JOIN (Branches
	JOIN Banks
		ON Bank_id = Banks.Id)
		ON Cities.Id = City_id
WHERE Cities.City_name = 'Gomel'
GO

/*TASK 2*/
SELECT Cards.Id AS [Card Id],
		 Client_name,
		 Cards.Balance,
		 Banks.Bank_name
FROM Cards
	JOIN ((Accounts
	JOIN Banks
		ON Bank_id = Banks.Id)
	JOIN Clients
		ON Client_id = Clients.Id)
		ON Account_id = Accounts.Id
GO

/*TASK 3*/
SELECT Cards.Account_id, SUM(Accounts.Balance) - SUM(Cards.Balance) AS diff
FROM Accounts 
	JOIN Cards ON Account_id = Accounts.Id
GROUP BY Cards.Account_id
HAVING SUM(Accounts.Balance) - SUM(Cards.Balance) <> 0


/*TASK 4*/
SELECT Social_statuses.Status_name,
		 COUNT(Cards.id) AS Cards_count
FROM Cards
RIGHT JOIN (Accounts
RIGHT JOIN (Clients
RIGHT JOIN (Social_statuses_register
RIGHT JOIN Social_statuses
	ON Social_statuses_register.Social_status_id = Social_statuses.Id)
	ON Clients.Id = Social_statuses_register.Client_id)
	ON Accounts.Client_id = Clients.Id)
	ON Cards.Account_id = Accounts.Id
GROUP BY  Social_statuses.Status_name 
GO

SELECT Status_name,		 
	(SELECT COUNT(*)
	FROM Cards
	JOIN (Accounts
	JOIN (Clients
	JOIN Social_statuses_register
		ON Clients.Id = Social_statuses_register.Client_id)
		ON Accounts.Client_id = Clients.Id)
		ON Cards.Account_id = Accounts.Id
	WHERE Social_statuses.Id = Social_statuses_register.Social_status_id) AS Cards_count
FROM Social_statuses
GO

/*TASK 5*/
CREATE PROCEDURE AddBalance 
	@id INT
AS 
BEGIN 
IF @id NOT IN
	(SELECT Social_statuses.Id
	FROM Social_statuses) THROW 51000, 'Social status not found!', 1; 
	IF NOT EXISTS
	(SELECT *
	FROM Clients
	JOIN Social_statuses_register
		ON Clients.Id = Social_statuses_register.Client_id
	WHERE @id = Social_statuses_register.Social_status_id) 
		THROW 51000, 'No account has this social status!', 1;
UPDATE Accounts SET Balance = Balance + 10
WHERE Client_id IN 
	(SELECT Clients.Id
	FROM Clients
	JOIN Social_statuses_register
		ON Clients.Id = Social_statuses_register.Client_id
	WHERE Social_statuses_register.Social_status_id = @id) 
END;

GO
SELECT * FROM Accounts
GO
EXEC AddBalance 4
GO
SELECT * FROM Accounts
GO

/*TASK 6*/
SELECT Clients.Id,
		 SUM(Accounts.Balance) - SUM(Cards.Balance) AS Available_funds
FROM Clients
JOIN ((Accounts
JOIN Cards
	ON Accounts.Id = Cards.Account_id)
JOIN Banks
	ON Accounts.Bank_id = Banks.Id)
	ON Clients.Id = Accounts.Client_id
GROUP BY  Clients.Id
GO

/*TASK 7*/
CREATE PROCEDURE SendToCard 
	@idCard INT,
	@sum MONEY
AS 
BEGIN 
	IF (@sum < 0)
		THROW 51000, 'Incorrect sum!', 1;
	IF @idCard NOT IN(SELECT Cards.Id
				  FROM Cards)
		THROW 51000, 'Card not found!', 1;
	DECLARE @sumCard MONEY
	SET @sumCard = (SELECT SUM(Cards.Balance)
					FROM Cards
					WHERE @idCard = Cards.Id
					GROUP BY Cards.Account_id)
	IF @sum + @sumCard > (SELECT Accounts.Balance
						  FROM Accounts JOIN Cards ON Cards.Account_id = Accounts.Id
						  WHERE Cards.Id = @idCard)
		THROW 51000, 'Not enought balance!', 1;
BEGIN TRANSACTION
	UPDATE Cards
	SET Balance = Balance + @sum
	WHERE @idCard = Cards.Id
COMMIT TRANSACTION
END;
GO

SELECT Accounts.Balance as Account_Balance, Cards.Balance as Card_Balance FROM Cards JOIN Accounts ON Accounts.Id = Cards.Account_id
GO
EXEC SendToCard 12, 100
GO
SELECT Accounts.Balance as Account_Balance, Cards.Balance as Card_Balance FROM Cards JOIN Accounts ON Accounts.Id = Cards.Account_id
GO


/*TASK 8*/
DROP TRIGGER IF EXISTS Accounts_Balance_Update
GO
CREATE TRIGGER Accounts_Balance_Update
ON Accounts
AFTER UPDATE
AS
BEGIN
	DECLARE @newSumAccount MONEY;
	DECLARE @Id INT;
	DECLARE @oldSumAccount MONEY;
	DECLARE @sumCards MONEY;
	SELECT @oldSumAccount = deleted.Balance
	FROM deleted
	SELECT @newSumAccount = inserted.Balance, @Id = inserted.Id
	FROM inserted
	SELECT @sumCards = SUM(Cards.Balance)
	FROM Cards, inserted
	WHERE inserted.Id = Cards.Account_id
	IF @sumCards > @newSumAccount
		BEGIN
			PRINT 'Wrong balance'
			UPDATE Accounts
			SET Balance = @oldSumAccount
			WHERE @id = Id
		END;
END;
GO
SELECT * FROM Accounts
GO
UPDATE Accounts
SET Balance = 1000, Bank_id = 1
WHERE Accounts.Id = 5
GO
SELECT * FROM Accounts
GO

DROP TRIGGER IF EXISTS Cards_Balance_Update
GO
CREATE TRIGGER Cards_Balance_Update
ON Cards
AFTER UPDATE
AS
IF (UPDATE(Balance))
BEGIN
	DECLARE @newSumCards MONEY;
	DECLARE @Account_id INT;
	DECLARE @Id INT;
	DECLARE @oldSumCard MONEY;
	DECLARE @sumAccounts MONEY;
	SELECT @Account_id = inserted.Account_id , @Id = Id
	FROM inserted
	SELECT @newSumCards = SUM(Balance)
	FROM Cards
	WHERE Cards.Account_id = @Account_id
	SELECT @oldSumCard = deleted.Balance
	FROM deleted
	SELECT @sumAccounts = Accounts.Balance
	FROM Accounts
	WHERE Accounts.Id = @Account_id
	IF @newSumCards > @sumAccounts
		BEGIN
			PRINT 'Wrong balance'
			UPDATE Cards
			SET Balance = @oldSumCard
			WHERE @Id = Cards.Id
		END;
END;

GO
SELECT * FROM Cards
GO
UPDATE Cards
SET Balance = 100
WHERE Cards.Id = 5
GO
SELECT * FROM Cards
GO