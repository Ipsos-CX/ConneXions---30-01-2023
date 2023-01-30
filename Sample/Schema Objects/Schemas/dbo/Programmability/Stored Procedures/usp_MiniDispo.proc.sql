CREATE PROCEDURE dbo.usp_MiniDispo
    @AuditId INT = NULL ,
    @Filename VARCHAR(100) = NULL ,
    @LoadedDate DATETIME = NULL
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SELECT 
             TOP 1000
            f.FileName ,
            f.FileRowCount ,
            v.VIN ,
            ar.RegistrationDate ,
            sq.*
    FROM    [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq
            INNER JOIN Vehicle.Vehicles v ON v.VehicleID = sq.MatchedODSVehicleID
            INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = sq.AuditID
            LEFT JOIN [$(AuditDB)].Audit.Registrations ar ON ar.AuditItemID = sq.AuditItemID
    WHERE   ( sq.AuditID = @AuditId
              OR @AuditId IS NULL
            )
            AND ( f.FileName = @Filename
                  OR @Filename IS NULL
                )
            AND ( sq.LoadedDate > @LoadedDate
                  OR @LoadedDate IS NULL
                )
    ORDER BY FileName ,
            PhysicalFileRow
    OPTION  ( RECOMPILE );


	GRANT EXECUTE ON usp_MiniDispo TO JLRExecLogin;

