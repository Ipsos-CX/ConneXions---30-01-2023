CREATE PROCEDURE [Selection].[uspRunSelection_NPSManual]

    @MIS VARCHAR(6) ,
    @ManufacturerPartyID TINYINT ,
    @CountryID SMALLINT ,
    @StartDays SMALLINT ,
    @EndDays SMALLINT ,
    @SelectionDate SMALLDATETIME
AS
    SET NOCOUNT ON
    SET XACT_ABORT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/* DECLARE LOCAL VARIABLES */

    DECLARE @QuestionnaireRequirementID INT
    DECLARE @SelectDate SMALLDATETIME

    DECLARE @ErrorNumber INT
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @ErrorLocation NVARCHAR(500)
    DECLARE @ErrorLine INT
    DECLARE @ErrorMessage NVARCHAR(2048)

    DECLARE @EventCategory VARCHAR(10)
    DECLARE @OwnershipCycle TINYINT
    DECLARE @SelectSales BIT
    DECLARE @SelectService BIT
    DECLARE @SelectWarranty BIT
    DECLARE @SelectRoadside BIT
    DECLARE @PersonRequired BIT
    DECLARE @OrganisationRequired BIT
    DECLARE @StreetRequired BIT
    DECLARE @PostcodeRequired BIT
    DECLARE @EmailRequired BIT
    DECLARE @TelephoneRequired BIT
    DECLARE @StreetOrEmailRequired BIT
    DECLARE @TelephoneOrEmailRequired BIT
    DECLARE @QuestionnaireIncompatibilityDays INT
    DECLARE @UpdateSelectionLogging BIT
	-- new stuff
    DECLARE @RowCount INT
    DECLARE @RetVal INT  -- returned value
    DECLARE @ProcedureName VARCHAR(100)

    SET @ProcedureName = OBJECT_NAME(@@PROCID)


    SET @SelectDate = SYSDATETIME();
   -- TRUNCATE TABLE dbo.Timings
    BEGIN TRY

	BEGIN TRANSACTION;
---------------------------------------------------------------------------------------------
		/* USE THE COUNTRYID TO GET TO THE CLP QUESTIONNAIRE REQUIREMENTID. WE NEED THIS TO LEVERAGE THE SALUTATION FUNCTION FOR DEAR NAME */

        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'USE THE COUNTRYID TO GET TO THE CLP QUESTIONNAIRE REQUIREMENTID. WE NEED THIS TO LEVERAGE THE SALUTATION FUNCTION FOR DEAR NAME'
                    
        SELECT  @QuestionnaireRequirementID = MIN(QuestionnaireRequirementID)
        FROM    [dbo].[vwBrandMarketQuestionnaireSampleMetadata]
        WHERE   Questionnaire = 'Sales'
                AND CountryID = @CountryID
                AND ManufacturerPartyID = @ManufacturerPartyID
                AND SelectionName LIKE CASE ManufacturerPartyID
                                         WHEN 2 THEN 'SAJ%'
                                         WHEN 3 THEN 'SAL%'
                                         ELSE 'SAJ%'
                                       END
        GROUP BY QuestionnaireRequirementID

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


		/* CHECK IN HOLDING TABLES EXIST. IF SO, DROP THEM */

        IF OBJECT_ID('tempdb..#SelectionParameters') IS NOT NULL
            DROP TABLE #SelectionParameters

        IF OBJECT_ID('tempdb..#MAXEVENTS') IS NOT NULL
            DROP TABLE #MAXEVENTS

        IF OBJECT_ID('tempdb..#SelectionBase') IS NOT NULL
            DROP TABLE #SelectionBase

		/* CREATE HOLDING TABLES */

        CREATE TABLE #SelectionParameters
            (
              MIS VARCHAR(6) ,
              StartDays INT ,
              EndDays INT ,
              SelectionDate DATETIME2 ,
              EventCategory VARCHAR(10) ,
              ManufacturerPartyID INT ,
              OwnershipCycle TINYINT ,
              CountryID INT ,
              SelectSales BIT ,
              SelectService BIT ,
              SelectWarranty BIT ,
              SelectRoadside BIT ,
              PersonRequired BIT ,
              OrganisationRequired BIT ,
              StreetRequired BIT ,
              PostcodeRequired BIT ,
              EmailRequired BIT ,
              TelephoneRequired BIT ,
              StreetOrEmailRequired BIT ,
              TelephoneOrEmailRequired BIT ,
              QuestionnaireIncompatibilityDays INT ,
              UpdateSelectionLogging BIT
            )

        INSERT  INTO #SelectionParameters
                ( MIS ,
                  StartDays ,
                  EndDays ,
                  SelectionDate ,
                  EventCategory ,
                  ManufacturerPartyID ,
                  OwnershipCycle ,
                  CountryID ,
                  SelectSales ,
                  SelectService ,
                  SelectWarranty ,
                  SelectRoadside ,
                  PersonRequired ,
                  OrganisationRequired ,
                  StreetRequired ,
                  PostcodeRequired ,
                  EmailRequired ,
                  TelephoneRequired ,
                  StreetOrEmailRequired ,
                  TelephoneOrEmailRequired ,
                  QuestionnaireIncompatibilityDays ,
                  UpdateSelectionLogging
				)
                SELECT  @MIS ,
                        @StartDays ,
                        @EndDays ,
                        @SelectionDate ,
                        'Sales' AS Questionnaire ,
                        @ManufacturerPartyID ,
                        1 AS OwnershipCycle ,
                        @CountryID ,
                        1 AS SelectSales ,
                        0 AS SelectService ,
                        0 AS SelectWarranty ,
                        0 AS SelectRoadside ,
                        1 AS PersonRequired ,
                        0 AS OrganisationRequired ,
                        0 AS StreetRequired ,
                        0 AS PostcodeRequired ,
                        0 AS EmailRequired ,
                        0 AS TelephoneRequired ,
                        0 AS StreetOrEmailRequired ,
                        1 AS TelephoneOrEmailRequired ,
                        0 AS QuestionnaireIncompatibilityDays ,
                        0 AS UpdateSelectionLogging

		/* POPULATE VARIABLES FROM TEMP TABLE */

        SELECT  @EventCategory = EventCategory ,
                @OwnershipCycle = OwnershipCycle ,
                @SelectSales = SelectSales ,
                @SelectService = SelectService ,
                @SelectWarranty = SelectWarranty ,
                @SelectRoadside = SelectRoadside ,
                @PersonRequired = PersonRequired ,
                @OrganisationRequired = OrganisationRequired ,
                @StreetRequired = StreetRequired ,
                @PostcodeRequired = PostcodeRequired ,
                @EmailRequired = EmailRequired ,
                @TelephoneRequired = TelephoneRequired ,
                @StreetOrEmailRequired = StreetOrEmailRequired ,
                @TelephoneOrEmailRequired = TelephoneOrEmailRequired ,
                @QuestionnaireIncompatibilityDays = QuestionnaireIncompatibilityDays ,
                @UpdateSelectionLogging = UpdateSelectionLogging
        FROM    #SelectionParameters


			
---------------------------------------------
			-- GET THE LATEST EVENTS WITH IN THE DATE RANGE FOR EACH PARTY
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET THE LATEST EVENTS WITH IN THE DATE RANGE FOR EACH PARTY'
                    
	/*  old code
        SELECT  VPRE.VehicleID ,
                ET.EventCategoryID ,
                EPR.PartyID AS DealerID ,
                VPRE.PartyID ,
                VPRE.VehicleRoleTypeID ,
                COALESCE(MAX(E.EventDate), MAX(REG.RegistrationDate)) AS MaxEventDate
        INTO    #MAXEVENTS
        FROM    Vehicle.VehiclePartyRoleEvents VPRE
                INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
                INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
                INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
                LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
                INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = VRE.RegistrationID
                                                        AND RegistrationDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate)
                                                                             AND     DATEADD(DAY, @StartDays, @SelectionDate) ON VRE.EventID = E.EventID
                                                                                                                                 AND VRE.VehicleID = VPRE.VehicleID
        WHERE   ET.EventCategory = @EventCategory
                AND COALESCE(E.EventDate, REG.RegistrationDate) BETWEEN DATEADD(DAY, @EndDays, @SelectionDate)
                                                                AND     DATEADD(DAY, @StartDays, @SelectionDate)
        GROUP BY VPRE.VehicleID ,
                ET.EventCategoryID ,
                EPR.PartyID ,
                VPRE.PartyID ,
                VPRE.VehicleRoleTypeID

*/		
--/*-- rewrite of above

;
        WITH    cte
                  AS ( SELECT   E.EventID ,
                                VPRE.VehicleID ,
                                EventCategoryID ,
                                VPRE.PartyID ,
                                VPRE.VehicleRoleTypeID ,
               -- E.EventDate,
               -- REG.RegistrationDate
                                EventDate
                       FROM     Vehicle.VehiclePartyRoleEvents VPRE
                                INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
                                INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
                       WHERE    ET.EventCategory = @EventCategory
				--E.EventTypeID IN (1,7,8,9)
                                AND ( E.EventDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate)
                                                  AND     DATEADD(DAY, @StartDays, @SelectionDate)
                                      OR E.EventDate IS NULL
                                    )
                     )
            SELECT  cte.VehicleID ,
                    cte.EventCategoryID ,
                    EPR.PartyID AS DealerID ,
                    cte.PartyID ,
                    cte.VehicleRoleTypeID ,
               -- E.EventDate,
               -- REG.RegistrationDate
                    COALESCE(MAX(cte.EventDate), MAX(REG.RegistrationDate)) AS MaxEventDate
            INTO    #MAXEVENTS
            FROM    cte
                    INNER JOIN Event.EventPartyRoles EPR ON cte.EventID = EPR.EventID
                    LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
                    INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = VRE.RegistrationID
                                                            AND RegistrationDate BETWEEN DATEADD(DAY, @EndDays, @SelectionDate)
                                                                                 AND     DATEADD(DAY, @StartDays, @SelectionDate) ON VRE.EventID = cte.EventID
                                                                                                                                     AND VRE.VehicleID = cte.VehicleID
            WHERE   COALESCE(cte.EventDate, REG.RegistrationDate) BETWEEN DATEADD(DAY, @EndDays, @SelectionDate)
                                                                  AND     DATEADD(DAY, @StartDays, @SelectionDate)
            GROUP BY cte.VehicleID ,
                    cte.EventCategoryID ,
                    EPR.PartyID ,
                    cte.PartyID ,
                    cte.VehicleRoleTypeID
--*/		
				
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

			

			-- CREATE A TABLE TO HOLD THE SELECTED EVENTS PRIOR TO REMOVING INAPPLICABLE RECORDS
			
		--Add a clustered index as well

        CREATE TABLE #SelectionBase
            (
              id INT IDENTITY(1, 1)
                     NOT NULL ,
              MIS VARCHAR(6) ,
              EventID INT ,
              VehicleID INT ,
              VehicleRoleTypeID TINYINT ,
              VIN NVARCHAR(50) ,
              EventCategory VARCHAR(10) ,
              EventCategoryID TINYINT ,
              EventType NVARCHAR(200) ,
              EventTypeID TINYINT ,
              EventDate DATETIME2 ,
              ManufacturerPartyID INT ,
              ModelID TINYINT ,
              PartyID INT ,
              RegistrationNumber NVARCHAR(100) ,
              RegistrationDate DATETIME2 ,
              OwnershipCycle TINYINT ,
              DealerPartyID INT ,
              DealerCode NVARCHAR(20) ,
              OrganisationPartyID INT ,
              CountryID INT ,
              PostalContactMechanismID INT ,
              Street NVARCHAR(400) ,
              Postcode NVARCHAR(60) ,
              EmailContactMechanismID INT ,
              PhoneContactMechanismID INT ,
              LandlineContactMechanismID INT ,
              MobileContactMechanismID INT ,
              CLPSalesCaseID INT ,
              CLPServiceCaseID INT ,
              RoadsideCaseID INT ,
              DeleteEventType BIT NOT NULL
                                  DEFAULT ( 0 ) ,
              DeletePersonRequired BIT NOT NULL
                                       DEFAULT ( 0 ) ,
              DeleteOrganisationRequired BIT NOT NULL
                                             DEFAULT ( 0 ) ,
              DeleteStreet BIT NOT NULL
                               DEFAULT ( 0 ) ,
              DeletePostcode BIT NOT NULL
                                 DEFAULT ( 0 ) ,
              DeleteEmail BIT NOT NULL
                              DEFAULT ( 0 ) ,
              DeleteTelephone BIT NOT NULL
                                  DEFAULT ( 0 ) ,
              DeleteStreetOrEmail BIT NOT NULL
                                      DEFAULT ( 0 ) ,
              DeleteTelephoneOrEmail BIT NOT NULL
                                         DEFAULT ( 0 ) ,
              DeleteRecontactPeriod BIT NOT NULL
                                        DEFAULT ( 0 ) ,
              DeleteSelected BIT NOT NULL
                                 DEFAULT ( 0 ) ,
              DeletePartyTypes BIT NOT NULL
                                   DEFAULT ( 0 ) ,
              DeleteEventNonSolicitation BIT NOT NULL
                                             DEFAULT ( 0 ) ,
              DeleteBarredEmail BIT NOT NULL
                                    DEFAULT ( 0 ) ,
              DeleteInvalidModel BIT NOT NULL
                                     DEFAULT ( 0 ) ,
              NewUsed CHAR(1) DEFAULT ( 'N' ) ,
              OriginalPartyID INT NULL ,
              CONSTRAINT pk_#SelectionBase PRIMARY KEY CLUSTERED ( Id )
            )

---------------------------------------------------------------
-- NOW GET THE EVENT DETAILS FOR THE LATEST EVENTS FOR EACH PARTY FOR THE CORRECT BRAND, OWNERSHIP CYCLE, FOR NON INTERNAL DEALERS AND WHERE WE HAVE PEOPLE OR ORGANISATION INFORMATION
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = '-- NOW GET THE EVENT DETAILS FOR THE LATEST EVENTS FOR EACH PARTY FOR THE CORRECT BRAND, OWNERSHIP CYCLE, FOR NON INTERNAL DEALERS AND WHERE WE HAVE PEOPLE OR ORGANISATION INFORMATION'         

			
        INSERT  INTO #SelectionBase
                ( MIS ,
                  EventID ,
                  VehicleID ,
                  VehicleRoleTypeID ,
                  VIN ,
                  EventCategory ,
                  EventCategoryID ,
                  EventType ,
                  EventTypeID ,
                  EventDate ,
                  ManufacturerPartyID ,
                  ModelID ,
                  PartyID ,
                  RegistrationNumber ,
                  RegistrationDate ,
                  OwnershipCycle ,
                  DealerPartyID ,
                  DealerCode ,
                  OrganisationPartyID ,
                  OriginalPartyID
			    )
                SELECT DISTINCT
                        @MIS ,
                        VE.EventID ,
                        VE.VehicleID ,
                        VE.VehicleRoleTypeID ,
                        VE.VIN ,
                        VE.EventCategory ,
                        VE.EventCategoryID ,
                        VE.EventType ,
                        VE.EventTypeID ,
                        VE.EventDate ,
                        VE.ManufacturerPartyID ,
                        VE.ModelID ,
                        VE.PartyID ,
                        VE.RegistrationNumber ,
                        VE.RegistrationDate ,
                        VE.OwnershipCycle ,
                        VE.DealerPartyID ,
                        VE.DealerCode ,
                        COALESCE(O.PartyID, BE.PartyID) AS OrganisationPartyID ,
                        VE.PartyID
                FROM    #MAXEVENTS M
                        INNER JOIN Meta.VehicleEvents VE ON VE.VehicleID = M.VehicleID
                                                            AND VE.EventCategoryID = M.EventCategoryID
                                                            AND VE.PartyID = M.PartyID
                                                            AND VE.VehicleRoleTypeID = M.VehicleRoleTypeID
                                                            AND VE.EventDate = M.MaxEventDate
                                                            AND VE.ManufacturerPartyID = @ManufacturerPartyID
                        LEFT JOIN Meta.BusinessEvents BE ON BE.EventID = VE.EventID
                        LEFT JOIN Party.DealershipClassifications DC ON DC.PartyID = VE.DealerPartyID
                                                                        AND DC.PartyTypeID = ( SELECT   PartyTypeID
                                                                                               FROM     Party.PartyTypes
                                                                                               WHERE    PartyType = 'Manufacturer Internal Dealership'
                                                                                             )
                        LEFT JOIN Party.People PP ON PP.PartyID = VE.PartyID
                        LEFT JOIN Party.Organisations O ON O.PartyID = VE.PartyID
                        LEFT JOIN Event.OwnershipCycle OC ON OC.EventID = VE.EventID
                WHERE   COALESCE(PP.PartyID, O.PartyID) IS NOT NULL -- EXCLUDE PARTIES WITH NO NAME
                        AND DC.PartyID IS NULL -- EXCLUDE INTERNAL DEALERS
                        AND ISNULL(OC.OwnershipCycle, 1) = COALESCE(@OwnershipCycle, OC.OwnershipCycle, 1)
                        
                        
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


		--EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
  --      @SubProcessName = 'Create index'      

		--CREATE INDEX IDX_#SelectionBase_PrtyId ON #SelectionBase (PartyId)
		
  --      SET @Rowcount = @@ROWCOUNT
  --      EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	   
			
-----------------------------------------------------------------------------		
		/* WE NEED TO SEE IF THERE IS A MORE RECENT PARTY ASSOCIATED WITH THE VEHICLE.
			IF SO, THE EVENT(S) NEEDS TO BE REMOVED FROM THE DATASET AS IT IS NOT ELLIGIBLE FOR SELECTION */

        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'WE NEED TO SEE IF THERE IS A MORE RECENT PARTY ASSOCIATED WITH THE VEHICLE.'

			
  --      ;WITH    cteVehiclesLastEvent
  --                AS ( SELECT DISTINCT
  --                              VE.VehicleID ,
  --                              VE.PartyID ,
  --                              VE.EventDate
  --                     FROM     Meta.VehicleEvents VE
  --                              INNER JOIN ( SELECT VehicleID ,
  --                                                  MAX(EventDate) EventDate
  --                                           FROM   Meta.VehicleEvents		

  --                                           GROUP BY VehicleID
  --                                         ) ME ON VE.EventDate = me.EventDate
  --                                                 AND VE.VehicleID = me.VehicleID
  --                                                 AND VE.EventType IN ( 'Sales', 'Service' )
  --                   )
  --          UPDATE  SB
  --          SET     PartyID = cteVehiclesLastEvent.PartyID ,
  --                  NewUsed = 'U'
  --          FROM    #SelectionBase SB
  --                  INNER JOIN cteVehiclesLastEvent ON SB.VehicleID = cteVehiclesLastEvent.VehicleID
  --                                                     AND SB.PartyID <> cteVehiclesLastEvent.PartyID
  --                                                     AND SB.EventDate < cteVehiclesLastEvent.EventDate

  --SET @Rowcount = @@ROWCOUNT
  --EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

-- slight rewrite of above

;
        WITH    cteVehiclesLastEvent
                  AS ( SELECT DISTINCT
                                VE.VehicleID ,
                                VE.PartyID ,
                                VE.EventDate
                       FROM     Meta.VehicleEvents VE
                                INNER JOIN ( SELECT m.VehicleID ,
                                                    MAX(m.EventDate) AS EventDate
                                             FROM   Meta.VehicleEvents M
                                                    JOIN #SelectionBase S ON s.vehicleid = M.vehicleId
                                             GROUP BY m.VehicleID
                                           ) ME ON VE.EventDate = me.EventDate
                                                   AND VE.VehicleID = me.VehicleID
                                                   AND VE.EventType IN ( 'Sales', 'Service' )
                     )
            UPDATE  SB
            SET     PartyID = cteVehiclesLastEvent.PartyID ,
                    NewUsed = 'U'
            FROM    #SelectionBase SB
                    INNER JOIN cteVehiclesLastEvent ON SB.VehicleID = cteVehiclesLastEvent.VehicleID
                                                       AND SB.PartyID <> cteVehiclesLastEvent.PartyID
                                                       AND SB.EventDate < cteVehiclesLastEvent.EventDate

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


            

----------------------------------------------------------------------------
		/* DOUBLE CHECK USED CAR OWNERS BY SEEING IF THE OLD AND NEW PARTIES SHARE ANY CONTACTMECHANISMS. IF SO, IT IS A NEW CAR OWNER */	

        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'DOUBLE CHECK USED CAR OWNERS BY SEEING IF THE OLD AND NEW PARTIES SHARE ANY CONTACTMECHANISMS. IF SO, IT IS A NEW CAR OWNER';
        WITH    cteNewCarOwners
                  AS ( SELECT DISTINCT
                                P.EventID ,
                                P.PartyID ,
                                OP.OriginalPartyID
                       FROM     ( SELECT    sb.EventID ,
                                            sb.PartyID ,
                                            pcm.ContactMechanismID
                                  FROM      #SelectionBase SB
                                            INNER JOIN Sample.ContactMechanism.PartyContactMechanisms PCM ON SB.PartyID = PCM.PartyID
                                                                                                             AND SB.NewUsed = 'U'
                                ) P
                                INNER JOIN ( SELECT SB.EventID ,
                                                    SB.OriginalPartyID ,
                                                    PCM.ContactMechanismID
                                             FROM   #SelectionBase SB
                                                    INNER JOIN Sample.ContactMechanism.PartyContactMechanisms PCM ON SB.OriginalPartyID = PCM.PartyID
                                                                                                                     AND SB.NewUsed = 'U'
                                           ) OP ON P.EventID = OP.EventID
                                                   AND P.ContactMechanismID = OP.ContactMechanismID /* BOTH PARTIES OLD AND NEW SHARE A CONTACT MECHANIMSM */
                     )
            UPDATE  SB
            SET     NewUsed = 'N'
            FROM    cteNewCarOwners NCO
                    INNER JOIN #SelectionBase SB ON NCO.EventID = SB.EventID
	
			
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	-----------------------------------------------------------------------------------
	
		/* REMOVE RECORDS DEEMED TO BE USED CARS */
		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'REMOVE RECORDS DEEMED TO BE USED CARS'
		
        DELETE  FROM #SelectionBase
        WHERE   NewUsed = 'U'
	
	
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------

        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'Exclude South Africa Records from this update as the address data not populated/reliable.'
		
		
			-- v1.17 / bug 10075 - Exclude South Africa Records from this update as the address data not populated/reliable.
        IF @CountryID <> ( SELECT   CountryID
                           FROM     ContactMechanism.Countries c
                           WHERE    Country = 'South Africa'
                         )
  --      BEGIN 
		--		-- GET THE ORGANISATION PARTYID IF WE'VE NOT ALREADY GOT IT BY CHECKING FOR ORGANISATIONS AT THE SAME ADDRESS
  --            	UPDATE SB
		--		SET SB.OrganisationPartyID = O.PartyID
		--		FROM #SelectionBase SB
		--		INNER JOIN ContactMechanism.PartyContactMechanisms PCM_P ON PCM_P.PartyID = SB.PartyID
		--		INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM_P.ContactMechanismID
		--		INNER JOIN ContactMechanism.PartyContactMechanisms PCM_O ON PCM_O.ContactMechanismID = PA.ContactMechanismID
		--		INNER JOIN Party.Organisations O ON O.PartyID = PCM_O.PartyID
		--		WHERE SB.OrganisationPartyID IS NULL
		--END		 
                				

                
             --re-write of above
			BEGIN                              
                ;
                WITH    cteSB
                          AS ( SELECT   SB.Id ,
                                        MAX(A.ContactMechanismID) AS ContactMechanismID
                               FROM     #SelectionBase SB
                                        JOIN ContactMechanism.PartyContactMechanisms C ON C.PartyID = SB.PartyID
                                        JOIN ContactMechanism.PostalAddresses A ON A.ContactMechanismID = C.ContactMechanismID
                               WHERE    SB.OrganisationPartyID IS NULL
										GROUP BY SB.Id
                             ),
                        cteOrg
                          AS ( SELECT   cteSB.Id ,
                                        O.PartyID 
                               FROM     Party.Organisations O
                                        JOIN ContactMechanism.PartyContactMechanisms C ON C.PartyID = O.PartyID
                                        JOIN ContactMechanism.PostalAddresses A ON A.ContactMechanismID = C.ContactMechanismID
                                        JOIN cteSB ON cteSB.ContactMechanismID = A.ContactMechanismID
                                        WHERE Street <> 'Unknown'
                               GROUP BY cteSB.Id ,
                                        O.PartyID 
                             )
                UPDATE  SB
		        SET     SB.OrganisationPartyID = cteOrg.PartyID
		        FROM    #SelectionBase SB
                        JOIN cteOrg ON cteOrg.Id = SB.ID
                 
               END         
                        
                
  
		
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

               

--------------------------------------------------------------------------------------------------
			-- NOW GET THE COUNTRY DETAILS: FIRSTLY USE THE POSTAL ADDRESS OF THE CUSOMTER, SECONDLY USE THE MARKET OF THE DEALER
			-- WHILE WE'RE HERE GET THE ADDRESS DETAILS AS WELL
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'NOW GET THE COUNTRY DETAILS: FIRSTLY USE THE POSTAL ADDRESS OF THE CUSOMTER, SECONDLY USE THE MARKET OF THE DEALER'
			
        UPDATE  SB
        SET     SB.CountryID = PA.CountryID ,
                SB.PostalContactMechanismID = PA.ContactMechanismID ,
                SB.Street = PA.Street ,
                SB.Postcode = PA.Postcode
        FROM    #SelectionBase SB
                INNER JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = SB.PartyID
                INNER JOIN ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
                
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount
        
---------------------------------------------------------------------------                
                
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'Not Sure';
        WITH    DealerCountries ( DealerPartyID, CountryID )
                  AS ( SELECT DISTINCT
                                PartyIDFrom ,
                                CountryID
                       FROM     ContactMechanism.DealerCountries
                     )
            UPDATE  SB
            SET     SB.CountryID = DC.CountryID
            FROM    #SelectionBase SB
                    INNER JOIN DealerCountries DC ON DC.DealerPartyID = SB.DealerPartyID
            WHERE   SB.CountryID IS NULL
            
            
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

--------------------------------------------------------------------------------

			-- NOW DELETE ALL THE RECORDS THAT DON'T BELONG TO THE REQUIRED CountryID
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW DELETE ALL THE RECORDS THAT DONT BELONG TO THE REQUIRED CountryID'        			
			
        DELETE  FROM #SelectionBase
        WHERE   ISNULL(CountryID, 0) <> @CountryID -- eliminating all records with no countryid / dont belong to required countryid bug 7569


        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

---------------------------------------------------------------------------------
			-- NOW CHECK IF WE ARE SELECTION THE EVENT TYPES
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'Various.....NOW CHECK IF WE ARE SELECTION THE EVENT TYPES'        			
			
        IF ISNULL(@SelectSales, 0) = 0
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Sales'
            END
        IF ISNULL(@SelectService, 0) = 0
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Service'
            END
        IF ISNULL(@SelectWarranty, 0) = 0
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Warranty'
            END		
        IF ISNULL(@SelectRoadside, 0) = 0
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Roadside'
            END


        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

------------------------------------------------------------------
			-- ADD IN EMAIL ContactMechanismID
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'ADD IN EMAIL ContactMechanismID'        			
		
        UPDATE  SB
        SET     SB.EmailContactMechanismID = PBEA.ContactMechanismID
        FROM    #SelectionBase SB
                INNER JOIN Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = SB.PartyID


        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

----------------------------------------------------------------------------------
			-- ADD IN TELEPHONE ContactMechanismIDs
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'ADD IN TELEPHONE ContactMechanismIDs'        				
			
        UPDATE  SB
        SET     SB.PhoneContactMechanismID = TN.PhoneID ,
                SB.LandlineContactMechanismID = TN.LandlineID ,
                SB.MobileContactMechanismID = TN.MobileID
        FROM    #SelectionBase SB
                INNER JOIN Meta.PartyBestTelephoneNumbers TN ON TN.PartyID = SB.PartyID
		
		
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

--------------------------------------------------------------------------------------		
		------ varoius updates to #SelectionBase
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'varoius updates to #SelectionBase'        				
		
        IF @PersonRequired = 1
            AND @OrganisationRequired = 0
            BEGIN
                UPDATE  SB
                SET     DeletePersonRequired = 1
                FROM    #SelectionBase SB
                        INNER JOIN Party.Organisations O ON O.PartyID = SB.PartyID
            END
        IF @PersonRequired = 0
            AND @OrganisationRequired = 1
            BEGIN
                UPDATE  SB
                SET     DeleteOrganisationRequired = 1
                FROM    #SelectionBase SB
                        INNER JOIN Party.People PP ON PP.PartyID = SB.PartyID
            END
        IF @PersonRequired = 1
            AND @OrganisationRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteOrganisationRequired = 0 ,
                        DeletePersonRequired = 0
            END 
        IF @StreetRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteStreet = 1
                WHERE   ISNULL(Street, '') = ''
            END
        IF @PostcodeRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeletePostcode = 1
                WHERE   ISNULL(Postcode, '') = ''
            END
        IF @EmailRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
            END
        IF @TelephoneRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteTelephone = 1
                WHERE   ISNULL(PhoneContactMechanismID, 0) = 0
                        AND ISNULL(LandlineContactMechanismID, 0) = 0
                        AND ISNULL(MobileContactMechanismID, 0) = 0
            END	
        IF @StreetRequired = 0
            AND @PostcodeRequired = 0
            AND @EmailRequired = 0
            AND @StreetOrEmailRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteStreetOrEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
                        AND ISNULL(Street, '') = ''
            END
        IF @StreetRequired = 0
            AND @PostcodeRequired = 0
            AND @EmailRequired = 0
            AND @TelephoneOrEmailRequired = 1
            BEGIN
                UPDATE  #SelectionBase
                SET     DeleteTelephoneOrEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
                        AND ISNULL(PhoneContactMechanismID, 0) = 0
                        AND ISNULL(LandlineContactMechanismID, 0) = 0
                        AND ISNULL(MobileContactMechanismID, 0) = 0
            END

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

------------------------------------------------------------------
			-- NOW EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED BY ONE OF THE PARTY TYPES WHICH HAS BEEN SET AS AN EXCLUSION
			-- PARTY TYPE CATEGORY FOR THIS QUESTIONNAIRE
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'NOW EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED BY ONE OF THE PARTY TYPES WHICH HAS BEEN SET AS AN EXCLUSION';
        WITH    EXPARTYTYPES ( PartyID )
                  AS ( SELECT   PC.PartyID
                       FROM     Party.PartyClassifications PC
                                INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
                                                                               AND PC.PartyTypeID = IC.PartyTypeID
                                INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
                                INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
                                INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
                                                                                                AND QPTR.PartyTypeID = QPTE.PartyTypeID
                                                                                                AND QPTR.FromDate = QPTE.FromDate
                       WHERE    QPTR.RequirementID = 92 /* USE THE JAG UK SALES QUESTIONNAIRE FOR PARTY TYPE EXCLUSIONS */
                     )
            UPDATE  SB
            SET     SB.DeletePartyTypes = 1
            FROM    #SelectionBase SB
                    INNER JOIN EXPARTYTYPES ON EXPARTYTYPES.PartyID = COALESCE(NULLIF(SB.OrganisationPartyID, 0), NULLIF(SB.PartyID, 0)) -- v1.4

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


-----------------------------------------------
			-- NOW CHECK EVENT NON SOLICITATIONS
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW CHECK EVENT NON SOLICITATIONS';
        WITH    EVENTNONSOL ( EventID )
                  AS ( SELECT DISTINCT
                                EventID
                       FROM     dbo.NonSolicitations ns
                                INNER JOIN Event.NonSolicitations ENS ON NS.NonSolicitationID = ENS.NonSolicitationID
                     )
            UPDATE  SB
            SET     SB.DeleteEventNonSolicitation = 1
            FROM    #SelectionBase SB
                    INNER JOIN EVENTNONSOL ON EVENTNONSOL.EventID = SB.EventID

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

-------------------------------------------------------
			-- NOW CHECK PARTIES WITH BARRED EMAILS
			
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW CHECK PARTIES WITH BARRED EMAILS';
        WITH    BarredEmails ( PartyID )
                  AS ( SELECT   PCM.PartyID
                       FROM     ContactMechanism.vwBlacklistedEmail BCM
                                INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
                       WHERE    BCM.PreventsSelection = 1
                     )
            UPDATE  SB
            SET     SB.DeleteBarredEmail = 1
            FROM    #SelectionBase SB
                    INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID

        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


------------------------------------------
	/* REMOVE ALL THE RECORDS WE DON'T WANT */

	-- NOW DELETE THE UNSELECTABLE RECORDS

        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW DELETE THE UNSELECTABLE RECORDS'        					

        DELETE  FROM #SelectionBase
        WHERE   DeleteBarredEmail = 1
                OR DeleteEmail = 1
                OR DeleteEventNonSolicitation = 1
                OR DeleteEventType = 1
                OR DeleteInvalidModel = 1
                OR DeletePartyTypes = 1
                OR DeletePostcode = 1
                OR DeleteRecontactPeriod = 1
                OR DeleteSelected = 1
                OR DeleteStreet = 1
                OR DeleteStreetOrEmail = 1
                OR DeleteTelephone = 1
                OR DeleteTelephoneOrEmail = 1
                OR DeletePersonRequired = 1
                OR DeleteOrganisationRequired = 1


        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount
---------------------------------------------------------------------------


	/* CAN'T DO RECONTACT PERIODS USING THE MODEL BECAUSE THE QUESTIONNAIRE DOESN'T ACTUALLY EXIST. JUST LOOK AT ANY CLP SALES QUESTIONNAIRES */

			-- NOW CHECK FOR ANY RECONTACT PERIODS
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW CHECK FOR ANY RECONTACT PERIODS';
        WITH    RecontactPeriod ( PartyID )
                  AS ( SELECT DISTINCT
                                AEBI.PartyID
                       FROM     Event.AutomotiveEventBasedInterviews AEBI
                                INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
                                INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
                                INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
                                INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
                       WHERE    P.Requirement = 'JLR 2004'
                                AND Q.Requirement LIKE '%Sales'
                                AND C.CreationDate >= DATEADD(DAY, -30, GETDATE())
                     )
            UPDATE  SB
            SET     SB.DeleteRecontactPeriod = 1
            FROM    #SelectionBase SB
                    INNER JOIN RecontactPeriod ON RecontactPeriod.PartyID = SB.PartyID
                    
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
-----------------------------------------------------
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'DELETE FROM #SelectionBase WHERE DeleteRecontactPeriod = 1'        					

        DELETE  FROM #SelectionBase
        WHERE   DeleteRecontactPeriod = 1
	
	
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

--------------------------------------------------------------------	
	
		/* GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES */	
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Sales';
        WITH    cteSaleCases
                  AS ( SELECT   AEBI.PartyID ,
                                MAX(AEBI.CaseID) AS CaseID
                       FROM     Event.AutomotiveEventBasedInterviews AEBI
                                INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
                                INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
                                INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
                                INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
                       WHERE    P.Requirement IN ( 'JLR 2004' )
                                AND Q.Requirement LIKE '%Sales'
                                AND C.ClosureDate IS NOT NULL
                       GROUP BY AEBI.PartyID
                     )
            UPDATE  SB
            SET     CLPSalesCaseID = SC.CaseID
            FROM    #SelectionBase SB
                    INNER JOIN cteSaleCases SC ON SB.PartyID = SC.PartyID
                    
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
-----------------------------------------------------------------                    
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Services';
        WITH    cteServiceCases
                  AS ( SELECT   AEBI.PartyID ,
                                MAX(AEBI.CaseID) AS CaseID
                       FROM     Event.AutomotiveEventBasedInterviews AEBI
                                INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
                                INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
                                INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
                                INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
                       WHERE    P.Requirement IN ( 'JLR 2004' )
                                AND Q.Requirement LIKE '%Service'
                                AND C.ClosureDate IS NOT NULL
                       GROUP BY AEBI.PartyID
                     )
            UPDATE  SB
            SET     CLPServiceCaseID = SC.CaseID
            FROM    #SelectionBase SB
                    INNER JOIN cteServiceCases SC ON SB.PartyID = SC.PartyID
                   
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
------------------------------------------------------------                    
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Roadside';
        WITH    cteRoadsideCases
                  AS ( SELECT   AEBI.PartyID ,
                                MAX(AEBI.CaseID) AS CaseID
                       FROM     Event.AutomotiveEventBasedInterviews AEBI
                                INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
                                INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
                                INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
                                INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
                                INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
                       WHERE    P.Requirement IN ( 'Roadside Survey' )
                                AND Q.Requirement LIKE '%Roadside'
                                AND C.ClosureDate IS NOT NULL
                       GROUP BY AEBI.PartyID
                     )
            UPDATE  SB
            SET     RoadsideCaseID = RC.CaseID
            FROM    #SelectionBase SB
                    INNER JOIN cteRoadsideCases RC ON SB.PartyID = RC.PartyID
	
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	
-------------------------------------------------------------------------------


		/* NEED TO WORK OUT THE NEXT CASEID IN THE RANGE. NEED TO DECIDE HOW THISIS GOING TO WORK */
		/* IDEALLY, WE SHOULD STORE ALL THE INFO REQUIRED FOR OUTPUTTING, PRE-FORMATTED IN PERMANAENT TABLE THEN JUST DO SELECTS TO GET THE DATA OUT*/

		
		/* OUTPUTTING - ONLINE FORMAT */
		
		

		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'OUTPUTTING - ONLINE FORMAT'        					                    

        INSERT  INTO Selection.NPS_SelectedEvents
                ( SelectionDate ,
                  MIS ,
                  EventID ,
                  VehicleID ,
                  VehicleRoleTypeID ,
                  [Password] ,
                  CaseID ,
                  FullModel ,
                  Model ,
                  VIN ,
                  sType ,
                  CarReg ,
                  Title ,
                  Initial ,
                  Surname ,
                  Fullname ,
                  DearName ,
                  CoName ,
                  PostalContactMechanismID ,
                  Add1 ,
                  Add2 ,
                  Add3 ,
                  Add4 ,
                  Add5 ,
                  Add6 ,
                  Add7 ,
                  Add8 ,
                  Add9 ,
                  CTRY ,
                  EmailAddress ,
                  Dealer ,
                  sno ,
                  ccode ,
                  modelcode ,
                  lang ,
                  manuf ,
                  gender ,
                  qver ,
                  blank ,
                  etype ,
                  reminder ,
                  [week] ,
                  test ,
                  SampleFlag ,
                  EventDate ,
                  DealerCode ,
                  RespondentPartyID ,
                  HomeNumber ,
                  WorkNumber ,
                  MobileNumber ,
                  ManufacturerDealerCode ,
                  ModelYear ,
                  OwnershipCycle ,
                  DealerPartyID ,
                  GDDDealerCode ,
                  SUPERNATIONALREGION ,
                  ReportingDealerPartyID ,
                  VariantID ,
                  ModelVariant ,
                  ITYPE ,
                  CLPSalesCaseID ,
                  CLPServiceCaseID ,
                  RoadSideCaseID ,
                  NewUsed	
		        )
                SELECT DISTINCT
                        @SelectDate ,
                        B.MIS ,
                        EventID ,
                        B.VehicleID ,
                        B.VehicleRoleTypeID ,
                        SelectionOutput.udfGeneratePassword() AS Password ,
                        ROW_NUMBER() OVER ( ORDER BY B.PartyID ) +
																	12384
																 + ( SELECT ISNULL(MAX(CaseID), 0)
                                                                     FROM   Selection.NPS_SelectedEvents
                                                                   ) AS [ID] ,
                        MD.ModelDescription AS FullModel ,
                        MD.OutputFileModelDescription Model ,
                        B.VIN ,
                        CASE WHEN B.ManufacturerPartyID = 2 THEN 'Jaguar'
                             ELSE 'Land Rover'
                        END AS sType ,
                        B.RegistrationNumber AS CarReg ,
                        T.Title ,
                        P.FirstName AS Initial ,
                        P.LastName AS Surname ,
                        T.Title + ' ' + P.FirstName + ' ' + P.LastName AS Fullname ,
                        Party.udfGetAddressingText(B.PartyID, @QuestionnaireRequirementID, B.CountryID, ISNULL(PL.LanguageID, 0),
                                                   ( SELECT AddressingTypeID
                                                     FROM   Party.AddressingTypes
                                                     WHERE  AddressingType = 'Salutation'
                                                   )) AS Salutation ,
                        O.OrganisationName AS CoName ,
                        PA.ContactMechanismID AS PostalContactMechanismID ,
                        ISNULL(PA.BuildingName,'') AS Add1 ,
                        ISNULL(PA.SubStreet,'') AS Add2 ,
                        ISNULL(PA.Street,'') AS Add3 ,
                        ISNULL(PA.SubLocality,'') AS Add4 ,
                        ISNULL(PA.Locality,'') AS Add5 ,
                        ISNULL(PA.Town,'') AS Add6 ,
                        ISNULL(PA.Region,'') AS Add7 ,
                        ISNULL(PA.PostCode,'') AS Add8 ,
                        '' AS Add9 ,
                        ISNULL(C.Country, '') AS CTRY ,
                        ISNULL(LTRIM(RTRIM(EA.EmailAddress)),'') ,
                        D.Outlet AS Dealer ,
                        0 AS sno ,
                        B.CountryID AS ccode ,
                        B.ModelID AS modelcode ,
                        ISNULL(PL.LanguageID, 0) AS lang ,
                        B.ManufacturerPartyID AS manuf ,
                        0 AS gender ,
                        0 AS qver ,
                        '' AS blank ,
                        B.EventTypeID AS etype ,
                        0 AS reminder ,
                        1 AS [week] ,
                        0 AS test ,
                        1 AS SampleFlag ,
                        CONVERT(VARCHAR(10), B.EventDate, 111) AS EventDate ,
                        B.DealerCode ,
                        B.PartyID AS RespondentPartyID ,
                        LTRIM(TNL.ContactNumber) AS HomeNumber ,
                        LTRIM(TNP.ContactNumber) AS WorkNumber ,
                        LTRIM(TNM.ContactNumber) AS MobileNumber ,
                        B.DealerCode AS ManufacturerDealerCode ,
                        V.BuildYear AS ModelYear ,
                        ISNULL(B.OwnershipCycle, 1) AS OwnershipCycle ,
                        OutletPartyID AS DealerPartyID ,
                        D.OutletCode_GDD AS GDDDealerCode ,
                        D.SUPERNATIONALREGION ,
                        TransferPartyID AS ReportingDealerPartyID ,
                        MV.VariantID ,
                        MV.Variant AS ModelVariant ,
				
                        CASE WHEN ISNULL(EA.EmailAddress,'') <> '' THEN 'H' 
							 WHEN LTRIM(TNM.ContactNumber) LIKE X.PrefixPattern THEN 'S'
							 WHEN LTRIM(TNL.ContactNumber) LIKE Y.PrefixPattern THEN 'S'
                             WHEN TNP.ContactNumber LIKE Z.PrefixPattern THEN 'S'
                        --Removed else case;we cannot send invite if there's no valid email or mobile number
                        END AS ITYPE ,
				
                        B.CLPSalesCaseID ,
                        B.CLPServiceCaseID ,
                        B.RoadSideCaseID ,
                        B.NewUsed
                FROM    #SelectionBase B
                        INNER JOIN Sample.Vehicle.Vehicles V ON B.VehicleID = V.VehicleID
                        INNER JOIN Sample.Vehicle.Models MD ON B.ModelID = MD.ModelID
                        INNER JOIN Sample.Vehicle.ModelVariants MV ON V.ModelVariantID = MV.VariantID
                        LEFT JOIN Sample.Party.People P
                        INNER JOIN Sample.Party.Titles T ON P.TitleID = T.TitleID ON B.PartyID = P.PartyID
                        LEFT JOIN Sample.Party.Organisations O ON B.OrganisationPartyID = O.PartyID
                        LEFT JOIN Sample.ContactMechanism.PostalAddresses PA
                        INNER JOIN Sample.ContactMechanism.Countries C ON PA.CountryID = C.CountryID ON B.PostalContactMechanismID = PA.ContactMechanismID
                        LEFT JOIN Sample.ContactMechanism.EmailAddresses EA ON B.EmailContactMechanismID = EA.ContactMechanismID
                        LEFT JOIN Sample.ContactMechanism.TelephoneNumbers TNM ON B.MobileContactMechanismID = TNM.ContactMechanismID
                        LEFT JOIN Sample.ContactMechanism.TelephoneNumbers TNL ON B.LandlineContactMechanismID = TNL.ContactMechanismID
                        LEFT JOIN Sample.ContactMechanism.TelephoneNumbers TNP ON B.PhoneContactMechanismID = TNP.ContactMechanismID
                        
                        
                        LEFT JOIN ( SELECT DISTINCT
                                            OutletPartyID ,
                                            TransferPartyID ,
                                            Outlet ,
                                            OutletCode_GDD ,
                                            SUPERNATIONALREGION
                                    FROM    Sample.dbo.DW_JLRCSPDealers
                                  ) D ON B.DealerPartyID = D.OutletPartyID
                        LEFT JOIN Sample.Party.PartyLanguages PL ON B.PartyID = PL.PartyID
                                                                    AND PL.PreferredFlag = 1			
			
			--EPT
                        --LEFT JOIN sample.Selection.NPS_MobilePhoneCodes MPC ON ( B.CountryID = MPC.CountryID )
                        --                                                       AND ( TNL.ContactNumber LIKE MPC.PrefixPattern )
                                                                               
                        LEFT JOIN sample.Selection.NPS_MobilePhoneCodes X ON (B.CountryID = X.CountryId) AND (TNM.ContactNumber LIKE X.PrefixPattern)
						LEFT JOIN sample.Selection.NPS_MobilePhoneCodes Y ON (B.CountryID = Y.CountryId) AND (TNL.ContactNumber LIKE Y.PrefixPattern)
						LEFT JOIN sample.Selection.NPS_MobilePhoneCodes Z ON (B.CountryID = Z.CountryId) AND (TNP.ContactNumber LIKE Z.PrefixPattern)                                                       
                                                                               
                                         
                                                                               
	
	
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	
--------------------------------------------------------------------------------			
		/* OUTPUTTING - ALL DATA */
		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'OUTPUTTING - ALL DATA'        					                    
	
        SELECT  RespondentPartyID AS PartyID ,
                CaseID AS [ID] ,
                FullModel ,
                Model ,
                sType ,
                CarReg ,
                Title ,
                Initial ,
                Surname ,
                Fullname ,
                DearName ,
                CoName ,
                Add1 ,
                Add2 ,
                Add3 ,
                Add4 ,
                Add5 ,
                Add6 ,
                Add7 ,
                Add8 ,
                Add9 ,
                CTRY ,
                EmailAddress ,
                Dealer ,
                sno ,
                ccode ,
                modelcode ,
                lang ,
                manuf ,
                gender ,
                qver ,
                blank ,
                etype ,
                reminder ,
                week ,
                test ,
                SampleFlag ,
                '' AS NewSurveyFile ,
                ITYPE ,
                '' AS Expired ,
                EventDate ,
                VIN ,
                DealerCode ,
                GDDDealerCode AS GlobalDealerCode ,
                HomeNumber ,
                WorkNumber ,
                MobileNumber ,
                ModelYear ,
                '' AS CustomerUniqueID ,
                OwnershipCycle ,
                '' AS PrivateOwner ,
                '' AS SalesEmployeeCode ,
                '' AS SalesEmployeeName ,
                '' AS ServiceEmployeeCode ,
                '' AS ServiceEmployeeName ,
                DealerPartyID ,
                Password ,
                ReportingDealerPartyID ,
                VariantID AS ModelVariantCode ,
                ModelVariant AS ModelVariantDescription ,
                CLPSalesCaseID ,
                CLPServiceCaseID ,
                RoadSideCaseID ,
                NewUsed ,
                1 AS CarOwnership ,
                MIS, 
                CTRY  as Market,
                SUPERNATIONALREGION
        FROM    Selection.NPS_SelectedEvents
        WHERE   SelectionDate = @SelectDate
                AND MIS = @MIS
                AND Manuf = @ManufacturerPartyID
                AND ccode = @CountryID
--        ORDER BY ITYPE DESC
		
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

-----------------------------------------------------------------------------------------



		
	
		/* OUTPUTTING - ONLINE ALL FILE */
		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'OUTPUTTING - ONLINE ALL FILE'        					                    
	
        SELECT  RespondentPartyID AS PartyID ,
                CaseID AS [ID] ,
                FullModel ,
                Model ,
                sType ,
                CarReg ,
                Title ,
                Initial ,
                Surname ,
                Fullname ,
                DearName ,
                CoName ,
                Add1 ,
                Add2 ,
                Add3 ,
                Add4 ,
                Add5 ,
                Add6 ,
                Add7 ,
                Add8 ,
                Add9 ,
                CTRY ,
                EmailAddress ,
                Dealer ,
                sno ,
                ccode ,
                modelcode ,
                lang ,
                manuf ,
                gender ,
                qver ,
                blank ,
                etype ,
                reminder ,
                week ,
                test ,
                SampleFlag ,
                '' AS NewSurveyFile ,
                ITYPE ,
                '' AS Expired ,
                EventDate ,
                VIN ,
                DealerCode ,
                GDDDealerCode AS GlobalDealerCode,
                ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](HomeNumber) AS HomeNumber,
                ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](WorkNumber) AS WorkNumber,
                ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](MobileNumber) AS MobileNumber,
                
                ModelYear ,
                '' AS CustomerUniqueID ,
                OwnershipCycle ,
                '' AS PrivateOwner ,
                '' AS SalesEmployeeCode ,
                '' AS SalesEmployeeName ,
                '' AS ServiceEmployeeCode ,
                '' AS ServiceEmployeeName ,
                DealerPartyID ,
                Password ,
                ReportingDealerPartyID ,
                VariantID AS ModelVariantCode ,
                ModelVariant AS ModelVariantDescription
        FROM    Selection.NPS_SelectedEvents SE
                LEFT JOIN Selection.NPS_TelphoneCountryCode TCC ON SE.ccode = TCC.CountryId
        WHERE   SelectionDate = @SelectDate
                AND MIS = @MIS
                AND Manuf = @ManufacturerPartyID
                AND ccode = @CountryID 



        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount




		/* OUTPUTTING - SMS FILE */
	
		
		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'OUTPUTTING - SMS FILE'        					                    		
		
        SELECT DISTINCT

                CASE 
					 WHEN MobileNumber LIKE X.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](MobileNumber)
                     WHEN HomeNumber LIKE Y.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](HomeNumber)
                     WHEN WorkNumber LIKE Z.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](WorkNumber)
                END AS Mobile , 
		
                RespondentPartyID ,
                sType ,
                CaseID AS [ID] ,
                password
        FROM    Selection.NPS_SelectedEvents SE 
                
                LEFT JOIN Selection.NPS_MobilePhoneCodes X ON (SE.ccode = X.CountryId) AND (SE.MobileNumber LIKE X.PrefixPattern)
				LEFT JOIN Selection.NPS_MobilePhoneCodes Y ON (SE.ccode = Y.CountryId) AND (SE.HomeNumber LIKE Y.PrefixPattern)
				LEFT JOIN Selection.NPS_MobilePhoneCodes Z ON (SE.ccode = Z.CountryId) AND (SE.WorkNumber LIKE Z.PrefixPattern) 
                
                LEFT JOIN Selection.NPS_TelphoneCountryCode TCC ON SE.ccode = TCC.CountryId

        WHERE   (SelectionDate = @SelectDate) AND 
                (MIS = @MIS) AND
                (Manuf = @ManufacturerPartyID) AND
                (ccode = @CountryID) AND         
			
			
				(ISNULL(EmailAddress,'') = '') AND
			
                (CASE WHEN MobileNumber LIKE X.PrefixPattern THEN MobileNumber
                     WHEN HomeNumber LIKE Y.PrefixPattern THEN HomeNumber
                     WHEN WorkNumber LIKE Z.PrefixPattern THEN WorkNumber
                     ELSE NULL
                END IS NOT NULL)
        
        ORDER BY CaseID
        
        SET @Rowcount = @@ROWCOUNT
        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount
                                                

	COMMIT TRANSACTION;		
    END TRY

BEGIN CATCH
	IF (XACT_STATE()) = 1 /* A COMMITABLE ACTIVE TRANSACTION */
		BEGIN 
			COMMIT TRANSACTION;
		END;
	IF (XACT_STATE()) = -1 /* TRANSACTION IN AN UNCOMMITABLE STATE */
		BEGIN
		
			SET @ErrorNumber = Error_Number()
			SET @ErrorSeverity = Error_Severity()
			SET @ErrorState = Error_State()
			SET @ErrorLocation = Error_Procedure()
			SET @ErrorLine = Error_Line()
			SET @ErrorMessage = Error_Message()

			EXEC [$(ErrorDB)].dbo.uspLogDatabaseError @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine, @ErrorMessage

			ROLLBACK TRANSACTION;
		END
END CATCH



RETURN 0