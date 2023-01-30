CREATE PROCEDURE [dbo].[uspUpdateTimings]
    @ProcessName VARCHAR(100) = 'Not provided' ,
    @SubProcessName VARCHAR(500) = 'Not provided' ,
    @NumberOfRowsProcessed INT = NULL ,
    @Id INT = NULL
AS
    DECLARE @Now DATETIME
    SET @Now = GETDATE()

    IF @Id IS NULL
        BEGIN
-- do insert

            INSERT  INTO Timings
                    ( ProcessName, SubProcessName )
            VALUES  ( @ProcessName, @SubProcessName )

            RETURN SCOPE_IDENTITY() 

        END

    ELSE
        BEGIN
-- do Update


            UPDATE  T
            SET     EndTime = @Now ,
                    NumberOfRowsProcessed = @NumberOfRowsProcessed ,
                    TimeTakenMinutes = DATEDIFF(ss, StartTime, @Now)
            FROM    dbo.Timings T
            WHERE   TimingId = @Id

            RETURN  -1 

        END




--DECLARE @RetVal INT

--EXEC @RetVal = uspUpdateTimings

--SELECT @RetVal

--EXEC @RetVal = uspUpdateTimings @Id = @RetVal

--SELECT @RetVal


--SELECT * FROM dbo.Timings












