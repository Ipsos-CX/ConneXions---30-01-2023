CREATE PROCEDURE CustomerUpdate.uspNonSolicitationRemoval_Update

AS

/*
	Purpose:	Generate AuditItems and write them to Audit and the customer update table
	
	Version			Date			Developer						Comment
	1.0				20/05/2014		Ali Yuksel			
	2.0				06-Jan-2015		Peter Doyle & Chris Ross		Complete rewrite to also reverse ContactMechanism
																	suppressions
	2.1				12/02/2015		Chris Ross						Add in check to ensure "hard set" non-solicitations are not removed
	2.2				10/01/2020		Chris Ledger					BUG 15372 - Fix Hard coded references to databases
*/


    SET NOCOUNT OFF

    DECLARE @ErrorNumber INT
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @ErrorLocation NVARCHAR(500)
    DECLARE @ErrorLine INT
    DECLARE @ErrorMessage NVARCHAR(2048)


    BEGIN TRY

        BEGIN TRAN

                     
        DECLARE @ProcessDate DATETIME           
        DECLARE @Output TABLE
            (
              NonSolicitationId INT NOT NULL ,
              partyId INT NOT NULL
            )

              
        SET @ProcessDate = GETDATE()

              ----Get unique list OF partyid's  
        SELECT  PartyID
        INTO    #Party
        FROM    [$(SampleDB)].dbo.NonSolicitations
        GROUP BY PartyID
      

        CREATE TABLE #NonSolRemovalAuditData
            (
              AuditID BIGINT NULL ,
              AuditItemID BIGINT NULL ,
              ParentAuditItemID BIGINT NULL ,
              FullName NVARCHAR(500) NULL ,
              VIN NVARCHAR(50) NULL ,
              EventDateOrig NVARCHAR(50) NULL ,
              EventDate DATE NULL ,
              DateLoaded DATETIME NULL ,
             -- NonSolicitationID INT ,
              PartyID INT ,
              EventId INT
            )
              
              
              --find matches on vehicle,name and eventddate
        INSERT  INTO #NonSolRemovalAuditData
                SELECT DISTINCT
                        nsr.AuditID ,
                        nsr.AuditItemID ,
                        nsr.ParentAuditItemID ,
                        nsr.FullName ,
                        nsr.VIN ,
                        nsr.EventDateOrig ,
                        e.EventDate ,
                        nsr.DateLoaded ,
                        --ns.NonSolicitationID ,
                        ns.PartyID ,
                        e.EventID
						FROM    CustomerUpdate.NonSolicitationRemoval nsr
                        INNER JOIN [$(SampleDB)].Vehicle.Vehicles v ON v.VIN = nsr.VIN
                        INNER JOIN [$(SampleDB)].Meta.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = v.VehicleID
                        INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = VPRE.EventID
                        LEFT JOIN #Party ns ON ns.PartyID = COALESCE(VPRE.PrincipleDriver,
                                                              VPRE.RegisteredOwner,
                                                              VPRE.Purchaser,
                                                              VPRE.OtherDriver)
                WHERE   e.EventDate = CONVERT(DATE, SUBSTRING(nsr.EventDateOrig,
                                                              1, 10), 103)
                        AND nsr.FullName = [$(SampleDB)].Party.udfGetAddressingText(COALESCE(VPRE.PrincipleDriver,
                                                              VPRE.RegisteredOwner,
                                                              VPRE.Purchaser,
                                                              VPRE.OtherDriver),
                                                              0, 219, 19,
                                                              ( SELECT
                                                              AddressingTypeID
                                                              FROM
                                                              [$(SampleDB)].Party.AddressingTypes
                                                              WHERE
                                                              AddressingType = 'Addressing'
                                                              ))
                        AND ns.PartyID IS NOT NULL   --- PETER: added this an there appear to be NULL PartyIds - perhaps needs investigating

                                                                                                       --AND  nsr.FULLNAME  = 'Mr Jaguar Australia'

      
-- Create table of all associated contact mechanisms for each party and event (this will be used to find any contactmechanism non-sols for each party)
        SELECT DISTINCT
                ns.PartyID ,
                ns.EventId ,
                l.MatchedODSEmailAddressID ,
                l.MatchedODSPrivEmailAddressID ,
                l.MatchedODSAddressID ,
                l.MatchedODSTelID ,
                l.MatchedODSPrivTelID ,
                l.MatchedODSBusTelID ,
                l.MatchedODSMobileTelID ,
                l.MatchedODSPrivMobileTelID
-- select ns.EventID  
        INTO    #Temp
        FROM    #NonSolRemovalAuditData ns
                INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging l ON l.MatchedODSEventID = ns.EventId
                                                              AND l.MatchedODSPersonID = ns.PartyID
                                                                                                --       ORDER BY ns.PartyID

     
                       -- drop table #final 
        SELECT  PartyID ,
                EventId ,                                 -- PETER: Added in EventId for linking to our main update temp table
                ContactMechanismId
        INTO    #Final
        FROM    ( SELECT  DISTINCT
                            PartyID ,
                            EventId ,
                            ContactMechanismId
                  FROM      #Temp UNPIVOT
   ( ContactMechanismId FOR ContactMechanisms IN ( MatchedODSEmailAddressID,
                                                   MatchedODSPrivEmailAddressID,
                                                   MatchedODSAddressID,
                                                   MatchedODSTelID,
                                                   MatchedODSPrivTelID,
                                                   MatchedODSBusTelID,
                                                   MatchedODSMobileTelID,
                                                   MatchedODSPrivMobileTelID ) ) AS unpvt
                ) AS X
				;


        --      SELECT *
        --      FROM    [$(SampleDB)].dbo.NonSolicitations NS
        --        JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
        --        JOIN #Final f ON f.PartyID = NS.PartyID
        --                         AND f.contactMechanismId = CMNS.ContactMechanismID
        --WHERE   ThroughDate IS NULL
        --        OR ThroughDate > @ProcessDate
              


              -- Table to hold non-soliciations linked back to Non-solicitation request records (also used to audit changes made)
        CREATE TABLE #NonSols
            (
              AuditItemID BIGINT ,
              PartyID INT ,
              ContactMechanismId INT ,
              NonSolicitationID INT ,
              NonSolType VARCHAR(50)
            )
              
              -- Get contactmechanism Non-solicitation IDs
        INSERT  INTO #NonSols
                ( AuditItemID ,
                  PartyID ,
                  ContactMechanismId ,
                  NonSolicitationID ,
                  NonSolType
                )
                SELECT  nsr.AuditItemID ,
                        nsr.PartyID ,
                        f.ContactMechanismID ,
                        CMNS.NonSolicitationID ,
                        'ContactMechanism' AS NonSolType
                FROM    #NonSolRemovalAuditData nsr
                        INNER JOIN #Final f ON f.PartyID = nsr.PartyID
                                               AND f.EventId = nsr.EventId
                        INNER JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.PartyID = nsr.PartyID
																		AND ISNULL(ns.hardset, 0) = 0	-- v2.1
                        INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON f.ContactMechanismID = CMNS.ContactMechanismID
                                                              AND CMNS.NonSolicitationID = ns.NonSolicitationID
                        --INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON f.ContactMechanismID = CMNS.ContactMechanismID
                        --INNER JOIN [$(SampleDB)].dbo.nonsolicitations ns ON ns.NonSolicitationID = CMNS.NonSolicitationID
                        --                                      AND ns.PartyID = nsr.PartyID
           
              -- Get Party Non-solictation IDs
        INSERT  INTO #NonSols
                ( AuditItemID ,
                  PartyID ,
                  ContactMechanismId ,
                  NonSolicitationID ,
                  NonSolType
                )
                SELECT DISTINCT
                        nsr.AuditItemID ,
                        nsr.PartyID ,
                        NULL AS ContactMechanismId ,
                        NS.NonSolicitationID ,
                        'Party' AS NonSolType
                FROM    #NonSolRemovalAuditData nsr
                        INNER JOIN #Final f ON f.PartyID = nsr.PartyID
                                               AND f.EventId = nsr.EventId
                        INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.PartyID = nsr.PartyID
																		AND ISNULL(ns.hardset, 0) = 0	-- v2.1
                        INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID




              -- Set through date on ContactMechanism.NonSolicatations
        ;
        WITH    CTE_NonSolIDs
                  AS ( SELECT DISTINCT
                                NonSolicitationID
                       FROM     #NonSols
                     )
            UPDATE  NS
            SET     ThroughDate = @ProcessDate ,
                    Notes = 'Reversal of ContactMechanism Non-Solicitation requested by exec.'
            FROM    CTE_NonSolIDs CN
                    INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.NonSolicitationID = CN.NonSolicitationID
            WHERE   ThroughDate IS NULL
                    OR ThroughDate > @ProcessDate

        


        -- Save Audit Information for requests received
        INSERT  INTO [$(AuditDB)].Audit.CustomerUpdate_NonSolicitationRemoval
                ( [AuditID] ,
                  [AuditItemID] ,
                  [ParentAuditItemID] ,
                  [FullName] ,
                  [VIN] ,
                  [EventDateOrig] ,
                  [EventDate] ,
                  [DateLoaded] ,
                  [DateProcessed] ,
              --    [NonSolicitationID] ,
                  [PartyID] ,
                  EventId
                )
                SELECT --DISTINCT
                        [AuditID] ,
                        [AuditItemID] ,
                        [ParentAuditItemID] ,
                        [FullName] ,
                        [VIN] ,
                        [EventDateOrig] ,
                        [EventDate] ,
                        [DateLoaded] ,
                        @ProcessDate ,
               --         O.[NonSolicitationId] ,
                        a.[PartyID] ,
                        a.EventId                                              -- PETER: Need to add in EventID into Audit table
                FROM    #NonSolRemovalAuditData a
             -- JOIN @Output O ON O.partyId = a.PartyID
                    


              -- PETER: You will need to create an extra Audit table to hold the actual non-sols updated.

              -- Save Audit information on actual Non-solications updated in this request       
        INSERT  INTO [$(AuditDB)].Audit.CustomerUpdate_NonSolicitationRemoval_NonSols
                ( AuditItemID ,
                  PartyID ,
                  ContactMechanismId ,
                  NonSolicitationID ,
                  NonSolType
                )
                SELECT  AuditItemID ,
                        PartyID ,
                        ContactMechanismId ,
                        NonSolicitationID ,
                        NonSolType
                FROM    #NonSols

        COMMIT TRAN

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRAN
            END

        EXEC usp_RethrowError

        --SELECT  @ErrorNumber = ERROR_NUMBER() ,
        --        @ErrorSeverity = ERROR_SEVERITY() ,
        --        @ErrorState = ERROR_STATE() ,
        --        @ErrorLocation = ERROR_PROCEDURE() ,
        --        @ErrorLine = ERROR_LINE() ,
        --        @ErrorMessage = ERROR_MESSAGE()

        --EXEC [$(ErrorDB)].dbo.uspLogDatabaseError @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine, @ErrorMessage
              
        --RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
              
    END CATCH


