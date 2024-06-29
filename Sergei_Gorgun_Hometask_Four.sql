-- 0. Create database if it does not exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'tic-tac-toe')
BEGIN
    CREATE DATABASE [tic-tac-toe];
END
GO

-- 1. Create gameboard:
USE [tic-tac-toe];
IF OBJECT_ID('TicTacToe', 'U') IS NOT NULL DROP TABLE TicTacToe;
CREATE TABLE TicTacToe
(
    ID INT NOT NULL PRIMARY KEY,
    A CHAR(1) NULL,
    B CHAR(1) NULL,
    C CHAR(1) NULL
);
INSERT INTO TicTacToe(ID, A, B, C)
VALUES
    (1, NULL, NULL, NULL),
    (2, NULL, NULL, NULL),
    (3, NULL, NULL, NULL);

-- 2. Player turn:
IF OBJECT_ID('PlayerTurn', 'U') IS NOT NULL DROP TABLE PlayerTurn;
CREATE TABLE PlayerTurn (turn CHAR(1) NOT NULL);
INSERT INTO PlayerTurn (turn) VALUES ('X');

-- 3. Check victory
IF OBJECT_ID('CheckVictory', 'P') IS NOT NULL DROP PROCEDURE CheckVictory;
GO
CREATE PROCEDURE CheckVictory
AS
BEGIN
    DECLARE 
        @A1 CHAR(1) = (SELECT A FROM TicTacToe WHERE ID = 1),
        @A2 CHAR(1) = (SELECT A FROM TicTacToe WHERE ID = 2),
        @A3 CHAR(1) = (SELECT A FROM TicTacToe WHERE ID = 3),
        @B1 CHAR(1) = (SELECT B FROM TicTacToe WHERE ID = 1),
        @B2 CHAR(1) = (SELECT B FROM TicTacToe WHERE ID = 2),
        @B3 CHAR(1) = (SELECT B FROM TicTacToe WHERE ID = 3),
        @C1 CHAR(1) = (SELECT C FROM TicTacToe WHERE ID = 1),
        @C2 CHAR(1) = (SELECT C FROM TicTacToe WHERE ID = 2),
        @C3 CHAR(1) = (SELECT C FROM TicTacToe WHERE ID = 3);

    SELECT *,
        CASE 
            WHEN @A1 = @B1 AND @B1 = @C1 AND @A1 IS NOT NULL THEN CONCAT('Player ', @A1, ' is victorious!')
            WHEN @A2 = @B2 AND @B2 = @C2 AND @A2 IS NOT NULL THEN CONCAT('Player ', @A2, ' is victorious!')
            WHEN @A3 = @B3 AND @B3 = @C3 AND @A3 IS NOT NULL THEN CONCAT('Player ', @A3, ' is victorious!')
            WHEN @A1 = @A2 AND @A2 = @A3 AND @A1 IS NOT NULL THEN CONCAT('Player ', @A1, ' is victorious!')
            WHEN @B1 = @B2 AND @B2 = @B3 AND @B1 IS NOT NULL THEN CONCAT('Player ', @B1, ' is victorious!')
            WHEN @C1 = @C2 AND @C2 = @C3 AND @C1 IS NOT NULL THEN CONCAT('Player ', @C1, ' is victorious!')
            WHEN @A1 = @B2 AND @B2 = @C3 AND @A1 IS NOT NULL THEN CONCAT('Player ', @A1, ' is victorious!')
            WHEN @A3 = @B2 AND @B2 = @C1 AND @A3 IS NOT NULL THEN CONCAT('Player ', @A3, ' is victorious!')
            ELSE 'Game is still ongoing'
        END AS Result,
        (SELECT turn FROM PlayerTurn) AS CurrentTurn
    FROM TicTacToe;
END;
GO

-- 4. New game:
IF OBJECT_ID('NewGame', 'P') IS NOT NULL DROP PROCEDURE NewGame;
GO
CREATE PROCEDURE NewGame
AS
BEGIN
    UPDATE TicTacToe SET A=NULL, B=NULL, C=NULL WHERE ID IN (1, 2, 3);
    UPDATE PlayerTurn SET turn = 'X';
    SELECT 'New game started' AS Message, 'X' AS CurrentTurn;
END;
GO

-- 5. Next move:
IF OBJECT_ID('NextMove', 'P') IS NOT NULL DROP PROCEDURE NextMove;
GO
CREATE PROCEDURE NextMove
    @Y CHAR(1),
    @X INT,
    @Val CHAR(1)
AS
BEGIN
    IF @Val NOT IN ('X', 'O')
    BEGIN
        SELECT 'Move must be X or O' AS Message;
        RETURN;
    END;
    
    IF @Y NOT IN ('A', 'B', 'C')
    BEGIN
        SELECT 'Column must be A, B or C' AS Message;
        RETURN;
    END;

    IF @X NOT IN (1, 2, 3)
    BEGIN
        SELECT 'Row must be 1, 2 or 3' AS Message;
        RETURN;
    END;

    DECLARE @existing_move CHAR(1);
    SET @existing_move = (SELECT CASE @Y
                                  WHEN 'A' THEN A
                                  WHEN 'B' THEN B
                                  WHEN 'C' THEN C
                              END
                         FROM TicTacToe
                         WHERE ID = @X);

    IF @existing_move IS NOT NULL
    BEGIN
        SELECT 'This position is already taken' AS Message;
        RETURN;
    END;

    IF @Val <> (SELECT turn FROM PlayerTurn)
    BEGIN
        SELECT CONCAT('This turn belongs to player ', (SELECT turn FROM PlayerTurn), '!') AS Message;
        RETURN;
    END;

    DECLARE @sql NVARCHAR(MAX) = N'UPDATE TicTacToe SET ' + @Y + ' = @Val WHERE ID = @X;';
    EXEC sp_executesql @sql, N'@Val CHAR(1), @X INT', @Val, @X;

    UPDATE PlayerTurn
    SET turn = CASE WHEN turn = 'X' THEN 'O' ELSE 'X' END;

    EXEC CheckVictory;
END;
GO

-- 6. Show board:
IF OBJECT_ID('ShowBoard', 'P') IS NOT NULL DROP PROCEDURE ShowBoard;
GO
CREATE PROCEDURE ShowBoard
AS
BEGIN
    SELECT 
        '1' AS Row, A AS A, B AS B, C AS C FROM TicTacToe WHERE ID = 1
    UNION ALL
    SELECT 
        '2' AS Row, A AS A, B AS B, C AS C FROM TicTacToe WHERE ID = 2
    UNION ALL
    SELECT 
        '3' AS Row, A AS A, B AS B, C AS C FROM TicTacToe WHERE ID = 3;
END;
GO

-- Play the game:
-- Start new game:
EXEC NewGame;
-- Player X turn:
EXEC NextMove 'A', 3, 'X';
-- Player O turn:
EXEC NextMove 'B', 3, 'O';
-- Show board state:
EXEC ShowBoard;
--Check victory:
EXEC CheckVictory;
