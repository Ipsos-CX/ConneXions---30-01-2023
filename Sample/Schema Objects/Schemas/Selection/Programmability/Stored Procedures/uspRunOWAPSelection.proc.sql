CREATE PROCEDURE [Selection].[uspRunOWAPSelection]

@SelectionRequirementID		[dbo].RequirementID 

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



	DECLARE	@BrandID INT
	DECLARE @QuestionnaireID INT
	DECLARE @StartDate DATETIME2
	DECLARE @EndDate DATETIME2
	DECLARE @PostCode VARCHAR(60)


	DECLARE		@ManufacturerPartyID INT,
				@EventCategory VARCHAR(10),
				@OwnershipCycle TINYINT,
				@SelectSales BIT,
				@SelectService BIT,
				@SelectWarranty BIT,
				@SelectPreOwned BIT,
				@SelectCRC BIT,
				@SelectLostLeads BIT,
				@SelectRoadside BIT,
				@SelectPreOwnedLostLeads BIT,
				@PersonRequired BIT,
				@OrganisationRequired BIT,
				@StreetRequired BIT,
				@PostcodeRequired BIT,
				@EmailRequired BIT,
				@TelephoneRequired BIT,
				@StreetOrEmailRequired BIT,
				@TelephoneOrEmailRequired BIT,
--				@QuestionnaireIncompatibilityDays INT,
				@UpdateSelectionLogging BIT

	-- new stuff
    DECLARE @RowCount INT
    DECLARE @RetVal INT  -- returned value
    DECLARE @ProcedureName VARCHAR(100)

    --SET @ProcedureName = OBJECT_NAME(@@PROCID)

    BEGIN TRY

	BEGIN TRANSACTION;

		-----------------------------------------------		
		--CHECK IF HOLDING TABLES EXIST. IF SO, DROP IT
		-----------------------------------------------
        IF OBJECT_ID('tempdb..#MAXEVENTS') IS NOT NULL
            DROP TABLE #MAXEVENTS

		TRUNCATE TABLE Selection.AdhocSelection_SelectionBase

		TRUNCATE TABLE SelectionOutput.AdhocSelection_OnlineOutput

		----------------------------------------------------------------
		--POPULATE VARIABLES FROM Requirement.AdhocSelectionRequirements
		----------------------------------------------------------------
		SELECT  
				@ManufacturerPartyID				= BR.ManufacturerPartyID,
				@QuestionnaireID					= ASR.QuestionnaireID,
				@StartDate							= ASR.StartDate,
				@EndDate							= ASR.EndDate,
				@PostCode							= ASR.PostCode,
				@EventCategory						= EC.EventCategory,
                --@OwnershipCycle						= OwnershipCycle ,
                @SelectSales						= CASE
															WHEN QN.[Questionnaire] = 'Sales' THEN 1
															ELSE 0
														END ,
                @SelectService						= CASE
															WHEN QN.[Questionnaire] = 'Service' THEN 1
															ELSE 0
														END ,
				--WARRANTY DOESN'T HAVE IT'S OWN QUESTIONNAIRE, THEY ARE A SUBTYPE OF SERVICE
				@SelectWarranty						= CASE
															WHEN QN.[Questionnaire] = 'Service' THEN 1
															ELSE 0
														END ,
                @SelectRoadside						= CASE
															WHEN QN.[Questionnaire] = 'Roadside' THEN 1
															ELSE 0
														END ,
				@SelectPreOwned						=	CASE
															WHEN QN.[Questionnaire] = 'PreOwned' THEN 1
															ELSE 0
														END ,
				@SelectCRC							=	CASE
															WHEN QN.[Questionnaire] = 'CRC' THEN 1
															ELSE 0
														END ,
				@SelectLostLeads					=	CASE
															WHEN QN.[Questionnaire] = 'LostLeads' THEN 1
															ELSE 0
														END ,
				@SelectPreOwnedLostLeads					=	CASE
															WHEN QN.[Questionnaire] = 'PreOwned LostLeads' THEN 1
															ELSE 0
														END ,
                @PersonRequired						= 1 ,
                @OrganisationRequired				= 0 ,
                @StreetRequired						= 0 ,
                @PostcodeRequired					= 0 ,
                @EmailRequired						= 0 ,
                @TelephoneRequired					= 0 ,
                @StreetOrEmailRequired				= 1 ,
                @TelephoneOrEmailRequired			= 1 ,
 --               @QuestionnaireIncompatibilityDays	= 0 ,
                @UpdateSelectionLogging				= 0
        FROM    Requirement.AdhocSelectionRequirements		ASR
		INNER JOIN dbo.Questionnaires						QN ON ASR.QuestionnaireID	= QN.QuestionnaireID
		INNER JOIN dbo.Brands								BR ON ASR.BrandID			= BR.BrandID
		INNER JOIN Event.EventCategories					EC ON QN.Questionnaire		= EC.EventCategory 
		WHERE	ASR.RequirementID =  @SelectionRequirementID


		--------------------------------------------------------------
		-- GET THE LATEST EVENTS WITH IN THE DATE RANGE FOR EACH PARTY
		--------------------------------------------------------------
        ;WITH    cte
                  AS ( SELECT   E.EventID ,
                                VPRE.VehicleID ,
                                EventCategoryID ,
                                VPRE.PartyID ,
                                VPRE.VehicleRoleTypeID ,
                                EventDate
                       FROM     Vehicle.VehiclePartyRoleEvents VPRE
                                INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
                                INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
                       WHERE    ET.EventCategory = @EventCategory
                                AND ( E.EventDate BETWEEN @StartDate AND @EndDate
                                      OR E.EventDate IS NULL
                                    )
                     )
            SELECT  cte.VehicleID ,
                    cte.EventCategoryID ,
                    EPR.PartyID AS DealerID ,
                    cte.PartyID ,
                    cte.VehicleRoleTypeID ,
                    COALESCE(MAX(cte.EventDate), MAX(REG.RegistrationDate)) AS MaxEventDate
            INTO    #MAXEVENTS
            FROM    cte
                    INNER JOIN Event.EventPartyRoles EPR ON cte.EventID = EPR.EventID
                    LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
                    INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = VRE.RegistrationID
                                                            AND RegistrationDate BETWEEN @StartDate
                                                                                 AND     @EndDate ON VRE.EventID = cte.EventID AND VRE.VehicleID = cte.VehicleID
          
			WHERE   COALESCE(cte.EventDate, REG.RegistrationDate) BETWEEN @StartDate AND @EndDate
            GROUP BY cte.VehicleID ,
                    cte.EventCategoryID ,
                    EPR.PartyID ,
                    cte.PartyID ,
                    cte.VehicleRoleTypeID
	
				

		------------------------------------------------------------------------------------
		-- GET THE EVENT DETAILS FOR THE LATEST EVENTS FOR EACH PARTY FOR THE CORRECT BRAND,
		-- FOR NON INTERNAL DEALERS AND WHERE WE HAVE PEOPLE OR ORGANISATION INFORMATION
		------------------------------------------------------------------------------------	
        INSERT  INTO Selection.AdhocSelection_SelectionBase
                ( EventID ,
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
				  ModelYear,
                  PartyID ,
                  RegistrationNumber ,
                  RegistrationDate ,
                  --OwnershipCycle ,
                  DealerPartyID ,
                  DealerCode ,
                  OrganisationPartyID ,
                  OriginalPartyID
			    )
                SELECT DISTINCT
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
						ISNULL(MY.ModelYear,0),
                        VE.PartyID ,
                        VE.RegistrationNumber ,
                        VE.RegistrationDate ,
                        --VE.OwnershipCycle ,
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
                        
						--LEFT JOIN
						
						LEFT JOIN Meta.BusinessEvents BE ON BE.EventID = VE.EventID
                        LEFT JOIN Party.DealershipClassifications DC ON DC.PartyID = VE.DealerPartyID
                                                                        AND DC.PartyTypeID = ( SELECT   PartyTypeID
                                                                                               FROM     Party.PartyTypes
                                                                                               WHERE    PartyType IN ('Manufacturer Internal Dealership', 'Customer-facing Dealership') 
                                                                                             )
                        LEFT JOIN Party.People PP ON PP.PartyID = VE.PartyID
                        LEFT JOIN Party.Organisations O ON O.PartyID = VE.PartyID

						LEFT JOIN Vehicle.Vehicles VEH ON VE.VehicleID = VEH.VehicleID
						LEFT JOIN Vehicle.ModelYear MY ON MY.VINCharacter = SUBSTRING(VEH.VIN , MY.VINPosition , 1) AND MY.ManufacturerPartyID = @ManufacturerPartyID

                        --LEFT JOIN Event.OwnershipCycle OC ON OC.EventID = VE.EventID
                WHERE   COALESCE(PP.PartyID, O.PartyID) IS NOT NULL -- EXCLUDE PARTIES WITH NO NAME
                        AND DC.PartyID IS NULL -- EXCLUDE INTERNAL DEALERS
                       -- AND ISNULL(OC.OwnershipCycle, 1) = COALESCE(@OwnershipCycle, OC.OwnershipCycle, 1)
                        
                        
			
-------------------------------------------------------------------------------		
--		/* WE NEED TO SEE IF THERE IS A MORE RECENT PARTY ASSOCIATED WITH THE VEHICLE.
--			IF SO, THE EVENT(S) NEEDS TO BE REMOVED FROM THE DATASET AS IT IS NOT ELLIGIBLE FOR SELECTION */

--        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
--            @SubProcessName = 'WE NEED TO SEE IF THERE IS A MORE RECENT PARTY ASSOCIATED WITH THE VEHICLE.'

			
--------------------------------------  WILL BIN THIS OFF AND REPLACE ------------------------------------
---- slight rewrite of above

--;
--        WITH    cteVehiclesLastEvent
--                  AS ( SELECT DISTINCT
--                                VE.VehicleID ,
--                                VE.PartyID ,
--                                VE.EventDate
--                       FROM     Meta.VehicleEvents VE
--                                INNER JOIN ( SELECT m.VehicleID ,
--                                                    MAX(m.EventDate) AS EventDate
--                                             FROM   Meta.VehicleEvents M
--                                                    JOIN Selection.AdhocSelection_SelectionBase S ON s.vehicleid = M.vehicleId
--                                             GROUP BY m.VehicleID
--                                           ) ME ON VE.EventDate = me.EventDate
--                                                   AND VE.VehicleID = me.VehicleID
--                                                   AND VE.EventType IN ( 'Sales', 'Service' )
--                     )
--            UPDATE  SB
--            SET     PartyID = cteVehiclesLastEvent.PartyID ,
--                    NewUsed = 'U'
--            FROM    Selection.AdhocSelection_SelectionBase SB
--                    INNER JOIN cteVehiclesLastEvent ON SB.VehicleID = cteVehiclesLastEvent.VehicleID
--                                                       AND SB.PartyID <> cteVehiclesLastEvent.PartyID
--                                                       AND SB.EventDate < cteVehiclesLastEvent.EventDate

--        SET @Rowcount = @@ROWCOUNT
--        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount


            

------------------------------------------------------------------------------
--		/* DOUBLE CHECK USED CAR OWNERS BY SEEING IF THE OLD AND NEW PARTIES SHARE ANY CONTACTMECHANISMS. IF SO, IT IS A NEW CAR OWNER */	

--        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
--            @SubProcessName = 'DOUBLE CHECK USED CAR OWNERS BY SEEING IF THE OLD AND NEW PARTIES SHARE ANY CONTACTMECHANISMS. IF SO, IT IS A NEW CAR OWNER';
--        WITH    cteNewCarOwners
--                  AS ( SELECT DISTINCT
--                                P.EventID ,
--                                P.PartyID ,
--                                OP.OriginalPartyID
--                       FROM     ( SELECT    sb.EventID ,
--                                            sb.PartyID ,
--                                            pcm.ContactMechanismID
--                                  FROM      Selection.AdhocSelection_SelectionBase SB
--                                            INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON SB.PartyID = PCM.PartyID
--                                                                                                             AND SB.NewUsed = 'U'
--                                ) P
--                                INNER JOIN ( SELECT SB.EventID ,
--                                                    SB.OriginalPartyID ,
--                                                    PCM.ContactMechanismID
--                                             FROM   Selection.AdhocSelection_SelectionBase SB
--                                                    INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON SB.OriginalPartyID = PCM.PartyID
--                                                                                                                     AND SB.NewUsed = 'U'
--                                           ) OP ON P.EventID = OP.EventID
--                                                   AND P.ContactMechanismID = OP.ContactMechanismID /* BOTH PARTIES OLD AND NEW SHARE A CONTACT MECHANIMSM */
--                     )
--            UPDATE  SB
--            SET     NewUsed = 'N'
--            FROM    cteNewCarOwners NCO
--                    INNER JOIN Selection.AdhocSelection_SelectionBase SB ON NCO.EventID = SB.EventID
	
			
--        SET @Rowcount = @@ROWCOUNT
--        EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	-----------------------------------------------------------------------------------
	
		--/* REMOVE RECORDS DEEMED TO BE USED CARS */
		
  --      EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'REMOVE RECORDS DEEMED TO BE USED CARS'
		
  --      DELETE  FROM Selection.AdhocSelection_SelectionBase
  --      WHERE   NewUsed = 'U'
	
	
  --      SET @Rowcount = @@ROWCOUNT
  --      EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

-------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------	
		-- V1.17 / BUG 10075 - EXCLUDE SOUTH AFRICA RECORDS FROM THIS UPDATE AS THE ADDRESS DATA NOT POPULATED/RELIABLE.
		----------------------------------------------------------------------------------------------------------------
  		BEGIN                              
				
				;WITH    cteSB
							AS ( SELECT SB.Id ,
										MAX(A.ContactMechanismID) AS ContactMechanismID
								FROM     Selection.AdhocSelection_SelectionBase SB
										INNER JOIN ContactMechanism.PartyContactMechanisms	C ON C.PartyID = SB.PartyID
										INNER JOIN ContactMechanism.PostalAddresses			A ON A.ContactMechanismID = C.ContactMechanismID
										INNER JOIN ContactMechanism.Countries				CN ON A.CountryID = CN.CountryID AND CN.Country <> 'South Africa'
								WHERE	SB.OrganisationPartyID IS NULL
										GROUP BY SB.Id
								),
						cteOrg
							AS ( SELECT	cteSB.Id ,
										O.PartyID 
								FROM	Party.Organisations O
										INNER JOIN ContactMechanism.PartyContactMechanisms	C ON C.PartyID = O.PartyID
										INNER JOIN ContactMechanism.PostalAddresses			A ON A.ContactMechanismID = C.ContactMechanismID
										INNER JOIN ContactMechanism.Countries				CN ON A.CountryID = CN.CountryID AND CN.Country <> 'South Africa'
										JOIN cteSB ON cteSB.ContactMechanismID = A.ContactMechanismID
										WHERE Street <> 'Unknown'
								GROUP BY cteSB.Id ,
										O.PartyID 
								)
				UPDATE  SB
				SET     SB.OrganisationPartyID = cteOrg.PartyID
				FROM    Selection.AdhocSelection_SelectionBase SB
						JOIN cteOrg ON cteOrg.Id = SB.ID
                 
		END                   
                
		---------------------------------------------------------------------------------------------------------------------	
		-- NOW GET THE COUNTRY DETAILS: FIRSTLY USE THE POSTAL ADDRESS OF THE CUSOMTER, SECONDLY USE THE MARKET OF THE DEALER
		-- WHILE WE'RE HERE GET THE ADDRESS DETAILS AS WELL
		---------------------------------------------------------------------------------------------------------------------
	    UPDATE  SB
        SET     SB.CountryID = PA.CountryID ,
                SB.PostalContactMechanismID = PA.ContactMechanismID ,
                SB.Street = PA.Street ,
                SB.Postcode = PA.Postcode
        FROM    Selection.AdhocSelection_SelectionBase SB
                INNER JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = SB.PartyID
                INNER JOIN ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
                


		; WITH DealerCountries (DealerPartyID, CountryID) AS (
			SELECT DISTINCT
				PartyIDFrom, CountryID
			FROM ContactMechanism.DealerCountries
				UNION
			SELECT PartyIDFrom, CountryID				
			FROM [Party].[CRCNetworks] crc
				UNION
			SELECT PartyIDFrom, CountryID				
			FROM [Party].[RoadsideNetworks] rn
		)
		UPDATE SB
		SET SB.CountryID = DC.CountryID
		FROM  Selection.AdhocSelection_SelectionBase SB
		INNER JOIN DealerCountries DC ON DC.DealerPartyID = SB.DealerPartyID
		WHERE SB.CountryID IS NULL


		-------------------------------------
		--POPULATE QUESTIONNAIREREQUIREMENTID
		-------------------------------------
		;WITH  QNReq_CTE (ManufacturerPartyID, CountryID, QuestionnaireRequirementID) 

		AS
		(
			SELECT		DISTINCT MD.ManufacturerPartyID, MD.CountryID, MD.QuestionnaireRequirementID
			FROM		dbo.vwBrandMarketQuestionnaireSampleMetadata	MD
			INNER JOIN	Requirement.AdhocSelectionMarketRequirements	AMR  ON MD.CountryID = AMR.CountryID AND AMR.RequirementIDPartOf = @SelectionRequirementID  
			WHERE		MD.ManufacturerPartyID	= @ManufacturerPartyID AND
						MD.Questionnaire		= @EventCategory		 
		)	

		UPDATE		SB
		SET			QuestionnaireRequirementID = CTE.QuestionnaireRequirementID
		FROM		Selection.AdhocSelection_SelectionBase	SB
		INNER JOIN	QNReq_CTE		CTE ON	SB.ManufacturerPartyID			= CTE.ManufacturerPartyID AND
											SB.CountryID					= CTE.CountryID
															




		---------------------------------------------------------------
		--CHECK THE POST CODE. ONLY APPLY IF POSTCODE FILTER IS PRESENT
		---------------------------------------------------------------		
		UPDATE	Selection.AdhocSelection_SelectionBase
		SET		DeleteInvalidPostCode = 1
		WHERE	(ISNULL(@PostCode,'') <> '' ) AND
		--		(CHARINDEX(REPLACE (@PostCode,' ',''),REPLACE (PostCode,' ','')) =0) 
				(CHARINDEX(@PostCode,PostCode) =0) 
		


		-------------------------------
		-- NOW CHECK FOR INVALID MODELS
		-------------------------------
		; WITH Models (ModelID) AS (

			SELECT			DISTINCT VMO.ModelID
			FROM            Requirement.AdhocSelectionModelRequirements	AMR 
			INNER JOIN		Requirement.Requirements					REQ ON AMR.RequirementIDMadeUpOf = REQ.RequirementID 
			INNER JOIN		Vehicle.Models								VMO	ON REQ.Requirement = VMO.ModelDescription
			WHERE			AMR.RequirementIDPartOf = @SelectionRequirementID
		)
		UPDATE Selection.AdhocSelection_SelectionBase
		SET DeleteInvalidModel = 1
		WHERE ModelID NOT IN (SELECT ModelID FROM Models)


		------------------------------------
		-- NOW CHECK FOR INVALID MODEL YEARS
		------------------------------------
		UPDATE	Selection.AdhocSelection_SelectionBase
		SET		DeleteInvalidModelYear = 1
		WHERE	ModelYear NOT IN (SELECT ModelYear FROM Requirement.AdhocSelectionModelYearRequirements WHERE RequirementIDPartOf = @SelectionRequirementID)


		------------------------------------------------------------------------
		--NOW DELETE ALL THE RECORDS THAT DON'T BELONG TO THE REQUIRED CountryID
		------------------------------------------------------------------------
        DELETE		Selection.AdhocSelection_SelectionBase
		WHERE		CountryID NOT IN 
					(
						SELECT	CountryId 
						FROM	Requirement.AdhocSelectionMarketRequirements
						WHERE	RequirementIDPartOf = @SelectionRequirementID 
					)
     
		
		------------------------------------------------
		-- NOW CHECK IF WE ARE SELECTION THE EVENT TYPES
		------------------------------------------------
		IF ISNULL(@SelectSales, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Sales'
            END
        IF ISNULL(@SelectService, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Service'
            END
        IF ISNULL(@SelectWarranty, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Warranty'
            END		
        IF ISNULL(@SelectRoadside, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'Roadside'
            END

		IF ISNULL(@SelectPreOwned, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'PreOwned'
            END

		IF ISNULL(@SelectCRC, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'CRC'
            END

		IF ISNULL(@SelectLostLeads, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'LostLeads'
            END

		IF ISNULL(@SelectPreOwnedLostLeads, 0) = 0
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEventType = 1
                WHERE   EventType = 'PreOwned LostLeads'
            END



		----------------------------------
		-- ADD IN EMAIL ContactMechanismID
		----------------------------------	
        UPDATE  SB
        SET     SB.EmailContactMechanismID = PBEA.ContactMechanismID
        FROM    Selection.AdhocSelection_SelectionBase SB
                INNER JOIN Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = SB.PartyID


       
		---------------------------------------
		-- ADD IN TELEPHONE ContactMechanismIDs
		---------------------------------------	       				
		UPDATE  SB
        SET     SB.PhoneContactMechanismID = TN.PhoneID ,
                SB.LandlineContactMechanismID = TN.LandlineID ,
                SB.MobileContactMechanismID = TN.MobileID
        FROM    Selection.AdhocSelection_SelectionBase SB
                INNER JOIN Meta.PartyBestTelephoneNumbers TN ON TN.PartyID = SB.PartyID
		

		-----------------------		
		--APPLY SELECTION FLAGS
        -----------------------      				
        IF @PersonRequired = 1
            AND @OrganisationRequired = 0
            BEGIN
                UPDATE  SB
                SET     DeletePersonRequired = 1
                FROM    Selection.AdhocSelection_SelectionBase SB
                        INNER JOIN Party.Organisations O ON O.PartyID = SB.PartyID
            END
        IF @PersonRequired = 0
            AND @OrganisationRequired = 1
            BEGIN
                UPDATE  SB
                SET     DeleteOrganisationRequired = 1
                FROM    Selection.AdhocSelection_SelectionBase SB
                        INNER JOIN Party.People PP ON PP.PartyID = SB.PartyID
            END
        IF @PersonRequired = 1
            AND @OrganisationRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteOrganisationRequired = 0 ,
                        DeletePersonRequired = 0
            END 
        IF @StreetRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteStreet = 1
                WHERE   ISNULL(Street, '') = ''
            END
        IF @PostcodeRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeletePostcode = 1
                WHERE   ISNULL(Postcode, '') = ''
            END
        IF @EmailRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
            END
        IF @TelephoneRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
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
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteStreetOrEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
                        AND ISNULL(Street, '') = ''
            END
        IF @StreetRequired = 0
            AND @PostcodeRequired = 0
            AND @EmailRequired = 0
            AND @TelephoneOrEmailRequired = 1
            BEGIN
                UPDATE  Selection.AdhocSelection_SelectionBase
                SET     DeleteTelephoneOrEmail = 1
                WHERE   ISNULL(EmailContactMechanismID, 0) = 0
                        AND ISNULL(PhoneContactMechanismID, 0) = 0
                        AND ISNULL(LandlineContactMechanismID, 0) = 0
                        AND ISNULL(MobileContactMechanismID, 0) = 0
            END

		---------------------------------------------------------------------------------------------------------------
		-- NOW EXCLUDE PARTIES THAT HAVE BEEN CATEGORISED BY ONE OF THE PARTY TYPES WHICH HAS BEEN SET AS AN EXCLUSION
		-- PARTY TYPE CATEGORY FOR BMQ
		;WITH  QNReq_CTE --(ManufacturerPartyID, CountryID, QuestionnaireRequirementID) 
		AS
		(
			SELECT		DISTINCT MD.ManufacturerPartyID, MD.CountryID, MD.QuestionnaireRequirementID
			FROM		dbo.vwBrandMarketQuestionnaireSampleMetadata	MD
			INNER JOIN	Requirement.AdhocSelectionMarketRequirements	AMR  ON MD.CountryID = AMR.CountryID AND AMR.RequirementIDPartOf = @SelectionRequirementID 
			WHERE		MD.ManufacturerPartyID = @ManufacturerPartyID
		),	
	    EXPARTYTYPES ---( PartyID, ManufacturerPartyID, CountryID, QuestionnaireRequirementID )
                  AS ( SELECT   DISTINCT PC.PartyID, QNR.ManufacturerPartyID, QNR.CountryID, QNR.QuestionnaireRequirementID 
                       FROM     Party.PartyClassifications PC
                                INNER JOIN Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
                                                                               AND PC.PartyTypeID = IC.PartyTypeID
                                INNER JOIN Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
                                INNER JOIN Requirement.QuestionnairePartyTypeRelationships QPTR ON PT.PartyTypeID = QPTR.PartyTypeID
                                INNER JOIN Requirement.QuestionnairePartyTypeExclusions QPTE ON QPTR.RequirementID = QPTE.RequirementID
                                                                                                AND QPTR.PartyTypeID = QPTE.PartyTypeID
                                                                                                AND QPTR.FromDate = QPTE.FromDate

								INNER JOIN QNReq_CTE QNR ON QPTR.RequirementID = QNR.QuestionnaireRequirementID
                     )
        UPDATE  SB
        SET     SB.DeletePartyTypes = 1
        FROM    Selection.AdhocSelection_SelectionBase SB
                INNER JOIN EXPARTYTYPES ON	EXPARTYTYPES.PartyID					= COALESCE(NULLIF(SB.OrganisationPartyID, 0), NULLIF(SB.PartyID, 0)) AND 
											EXPARTYTYPES.ManufacturerPartyID		= SB.ManufacturerPartyID AND
											EXPARTYTYPES.CountryID					= SB.CountryID AND
											EXPARTYTYPES.QuestionnaireRequirementID	= SB.QuestionnaireRequirementID			 

       
		------------------------------------
		-- NOW CHECK EVENT NON SOLICITATIONS
        ------------------------------------
		;WITH    EVENTNONSOL ( EventID )
            AS ( SELECT DISTINCT
                        EventID
                FROM     dbo.NonSolicitations ns
                        INNER JOIN Event.NonSolicitations ENS ON NS.NonSolicitationID = ENS.NonSolicitationID
                )
		UPDATE  SB
		SET     SB.DeleteEventNonSolicitation = 1
		FROM    Selection.AdhocSelection_SelectionBase SB
				INNER JOIN EVENTNONSOL ON EVENTNONSOL.EventID = SB.EventID



		---------------------------------------
		-- NOW CHECK PARTIES WITH BARRED EMAILS
		---------------------------------------	
        ;WITH    BarredEmails ( PartyID )
                  AS ( SELECT   PCM.PartyID
                       FROM     ContactMechanism.vwBlacklistedEmail BCM
                                INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
                       WHERE    BCM.PreventsSelection = 1
                     )
        UPDATE  SB
        SET     SB.DeleteBarredEmail = 1
        FROM    Selection.AdhocSelection_SelectionBase SB
                INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID



		---------------------------------------------------------------------------


			--/* CAN'T DO RECONTACT PERIODS USING THE MODEL BECAUSE THE QUESTIONNAIRE DOESN'T ACTUALLY EXIST. JUST LOOK AT ANY CLP SALES QUESTIONNAIRES */

			--		-- NOW CHECK FOR ANY RECONTACT PERIODS
		 --       EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'NOW CHECK FOR ANY RECONTACT PERIODS';
		 --       WITH    RecontactPeriod ( PartyID )
		 --                 AS ( SELECT DISTINCT
		 --                               AEBI.PartyID
		 --                      FROM     Event.AutomotiveEventBasedInterviews AEBI
		 --                               INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
		 --                               INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
		 --                               INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
		 --                               INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
		 --                               INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
		 --                               INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
		 --                      WHERE    P.Requirement = 'JLR 2004'
		 --                               AND Q.Requirement LIKE '%Sales'
		 --                               AND C.CreationDate >= DATEADD(DAY, -30, GETDATE())
		 --                    )
		 --           UPDATE  SB
		 --           SET     SB.DeleteRecontactPeriod = 1
		 --           FROM    Selection.AdhocSelection_SelectionBase SB
		 --                   INNER JOIN RecontactPeriod ON RecontactPeriod.PartyID = SB.PartyID
                    
		 --       SET @Rowcount = @@ROWCOUNT
		 --       EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
		-----------------------------------------------------
	

		------------------------------
		-- REMOVE NON ELIGIBLE RECORDS
		------------------------------
		DELETE  FROM Selection.AdhocSelection_SelectionBase
		WHERE   DeleteBarredEmail			= 1 OR 
				DeleteEmail					= 1 OR
				DeleteEventNonSolicitation	= 1 OR
				DeleteEventType				= 1 OR
				DeleteInvalidModel			= 1 OR
				DeletePartyTypes			= 1 OR
				DeletePostcode				= 1 OR
				DeleteRecontactPeriod		= 1 OR
				DeleteSelected				= 1 OR
				DeleteStreet				= 1 OR
				DeleteStreetOrEmail			= 1 OR
				DeleteTelephone				= 1 OR
				DeleteTelephoneOrEmail		= 1 OR
				DeletePersonRequired		= 1 OR
				DeleteOrganisationRequired	= 1 OR
				DeleteInvalidModel			= 1 OR
				DeleteInvalidModelYear		= 1 OR 
				DeleteInvalidPostCode		= 1 OR
				DeleteRecontactPeriod		= 1



--------------------------------------------------------------------	
	
		/* GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES */	
        --EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Sales';
        --WITH    cteSaleCases
        --          AS ( SELECT   AEBI.PartyID ,
        --                        MAX(AEBI.CaseID) AS CaseID
        --               FROM     Event.AutomotiveEventBasedInterviews AEBI
        --                        INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
        --                        INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
        --                        INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
        --                        INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
        --               WHERE    P.Requirement IN ( 'JLR 2004' )
        --                        AND Q.Requirement LIKE '%Sales'
        --                        AND C.ClosureDate IS NOT NULL
        --               GROUP BY AEBI.PartyID
        --             )
        --    UPDATE  SB
        --    SET     CLPSalesCaseID = SC.CaseID
        --    FROM    Selection.AdhocSelection_SelectionBase SB
        --            INNER JOIN cteSaleCases SC ON SB.PartyID = SC.PartyID
                    
        --SET @Rowcount = @@ROWCOUNT
        --EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
-----------------------------------------------------------------                    
        --EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Services';
        --WITH    cteServiceCases
        --          AS ( SELECT   AEBI.PartyID ,
        --                        MAX(AEBI.CaseID) AS CaseID
        --               FROM     Event.AutomotiveEventBasedInterviews AEBI
        --                        INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
        --                        INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
        --                        INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
        --                        INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
        --               WHERE    P.Requirement IN ( 'JLR 2004' )
        --                        AND Q.Requirement LIKE '%Service'
        --                        AND C.ClosureDate IS NOT NULL
        --               GROUP BY AEBI.PartyID
        --             )
        --    UPDATE  SB
        --    SET     CLPServiceCaseID = SC.CaseID
        --    FROM    Selection.AdhocSelection_SelectionBase SB
        --            INNER JOIN cteServiceCases SC ON SB.PartyID = SC.PartyID
                   
        --SET @Rowcount = @@ROWCOUNT
        --EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

                    
------------------------------------------------------------                    
        --EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'GET CASEIDS OF RETURNED CASES FOR THE SELECTED PARTIES - Roadside';
        --WITH    cteRoadsideCases
        --          AS ( SELECT   AEBI.PartyID ,
        --                        MAX(AEBI.CaseID) AS CaseID
        --               FROM     Event.AutomotiveEventBasedInterviews AEBI
        --                        INNER JOIN Event.Cases C ON AEBI.CaseID = C.CaseID
        --                        INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
        --                        INNER JOIN Requirement.RequirementRollups SQ ON SC.RequirementIDPartOf = SQ.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements Q ON SQ.RequirementIDPartOf = Q.RequirementID
        --                        INNER JOIN Requirement.RequirementRollups QP ON Q.RequirementID = QP.RequirementIDMadeUpOf
        --                        INNER JOIN Requirement.Requirements P ON QP.RequirementIDPartOf = P.RequirementID
        --               WHERE    P.Requirement IN ( 'Roadside Survey' )
        --                        AND Q.Requirement LIKE '%Roadside'
        --                        AND C.ClosureDate IS NOT NULL
        --               GROUP BY AEBI.PartyID
        --             )
        --    UPDATE  SB
        --    SET     RoadsideCaseID = RC.CaseID
        --    FROM    Selection.AdhocSelection_SelectionBase SB
        --            INNER JOIN cteRoadsideCases RC ON SB.PartyID = RC.PartyID
	
        --SET @Rowcount = @@ROWCOUNT
        --EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount

	
-------------------------------------------------------------------------------

		----------------------------
		--OUTPUTTING - ONLINE FORMAT
		----------------------------
		INSERT  INTO SelectionOutput.AdhocSelection_OnlineOutput
		(	
			ID,
			RequirementID,
			PartyID,
			FullModel,
			Model,
			sType,
			CarReg,
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
            [week] ,
            test ,
            SampleFlag,
			SurveyFile,
			ITYPE,
			Expired,
			EventDate ,
			VIN ,
			DealerCode ,
            GlobalDealerCode,
			LandPhone,
            WorkPhone,
            MobilePhone,
            ModelYear ,
            CustomerUniqueID, 
			--OwnershipCycle ,
			EmployeeCode,
			EmployeeName,
            DealerPartyID ,
            [Password] ,
			ReportingDealerPartyID ,
            ModelVariantCode ,
            ModelVariantDescription,
			SelectionDate, 
            CampaignId,
			PilotCode,
			EmailContactMechanismID ,
			PhoneContactMechanismID ,
			LandlineContactMechanismID ,
			MobileContactMechanismID , 
			PostalContactMechanismID ,
			EventID ,
			VehicleID
            --VehicleRoleTypeID , 
            --NewUsed	
		)
        SELECT DISTINCT
            ROW_NUMBER() OVER ( ORDER BY B.PartyId  ASC),
			@SelectionRequirementID,
			B.PartyID,
			MD.ModelDescription AS FullModel ,
			MD.OutputFileModelDescription Model ,
			CASE WHEN B.ManufacturerPartyID = 2 THEN 'Jaguar'
					ELSE 'Land Rover'
			END AS sType ,
			B.RegistrationNumber AS CarReg ,
			T.Title ,
			P.FirstName AS Initial ,
			P.LastName AS Surname ,
            T.Title + ' ' + P.FirstName + ' ' + P.LastName AS Fullname ,
			Party.udfGetAddressingText(B.PartyID, B.QuestionnaireRequirementID, B.CountryID, COALESCE(PL.LanguageID, C.DefaultLanguageID,0),
                                            ( SELECT AddressingTypeID
                                                FROM   Party.AddressingTypes
                                                WHERE  AddressingType = 'Salutation'
                                            )) AS Salutation ,
			O.OrganisationName AS CoName ,
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
            0 AS [week] ,
            0 AS test ,
            1 AS SampleFlag ,
			'' AS SurveyFile,
			'H' AS ITYPE,
			null AS Expired,
			CONVERT(VARCHAR, B.EventDate, 103) AS EventDate ,
			B.VIN ,
			B.DealerCode,
			D.OutletCode_GDD AS GDDDealerCode ,
            TNL.ContactNumber AS HomeNumber ,
			TNP.ContactNumber AS WorkNumber ,
            TNM.ContactNumber AS MobileNumber ,  
			V.BuildYear AS ModelYear , 
			'' AS CustomerUniqueID,   --							<-- need to add this in 
			--ISNULL(B.OwnershipCycle, 1) AS OwnershipCycle		<-- need to add this in   
			'' AS EmployeeCode,
			'' AS EmployeeName,
			OutletPartyID AS DealerPartyID ,
            SelectionOutput.udfGeneratePassword() AS Password ,
            TransferPartyID AS ReportingDealerPartyID ,
			MV.VariantID ,
            MV.Variant AS ModelVariant,
			@SelectDate ,
			CONVERT(NVARCHAR(100),
            CONVERT(VARCHAR(10), ISNULL(B.EventTypeID, '')) + '_'
            + 'H' + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(B.CountryID, '')) + '_'
            + CASE WHEN B.ManufacturerPartyID = 2 THEN 'J'
                   WHEN B.ManufacturerPartyID = 3 THEN 'L'
                   ELSE 'UnknownManufacturer'
              END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(PL.LanguageID, ''))) AS CampaignId,
			'' AS PilotCode,
			B.EmailContactMechanismID ,
			B.PhoneContactMechanismID ,
			B.LandlineContactMechanismID ,
			B.MobileContactMechanismID , 
			B.PostalContactMechanismID,	    
			B.EventID ,
            B.VehicleID
                --B.VehicleRoleTypeID ,
                -- B.NewUsed
        FROM    Selection.AdhocSelection_SelectionBase B
                INNER JOIN Vehicle.Vehicles V ON B.VehicleID = V.VehicleID
                INNER JOIN Vehicle.Models MD ON B.ModelID = MD.ModelID
                INNER JOIN Vehicle.ModelVariants MV ON V.ModelVariantID = MV.VariantID
                LEFT JOIN Party.People P
                INNER JOIN Party.Titles T ON P.TitleID = T.TitleID ON B.PartyID = P.PartyID
                LEFT JOIN Party.Organisations O ON B.OrganisationPartyID = O.PartyID
                LEFT JOIN ContactMechanism.PostalAddresses PA
                INNER JOIN ContactMechanism.Countries C ON PA.CountryID = C.CountryID ON B.PostalContactMechanismID = PA.ContactMechanismID
                LEFT JOIN ContactMechanism.EmailAddresses EA ON B.EmailContactMechanismID = EA.ContactMechanismID
                LEFT JOIN ContactMechanism.TelephoneNumbers TNM ON B.MobileContactMechanismID = TNM.ContactMechanismID
                LEFT JOIN ContactMechanism.TelephoneNumbers TNL ON B.LandlineContactMechanismID = TNL.ContactMechanismID
                LEFT JOIN ContactMechanism.TelephoneNumbers TNP ON B.PhoneContactMechanismID = TNP.ContactMechanismID
                        
                        
                LEFT JOIN ( SELECT DISTINCT
                                    OutletPartyID ,
                                    TransferPartyID ,
                                    Outlet ,
                                    OutletCode_GDD ,
                                    SUPERNATIONALREGION
                            FROM    dbo.DW_JLRCSPDealers
                            ) D ON B.DealerPartyID = D.OutletPartyID
                LEFT JOIN Party.PartyLanguages PL ON B.PartyID = PL.PartyID
                                                            AND PL.PreferredFlag = 1			
			
		-------------------------------------------
		-- UPDATE THE DATA IN SelectionRequirements
		-------------------------------------------
		UPDATE	Requirement.AdhocSelectionRequirements
		SET		SelectionStatusTypeID	=
											CASE
													WHEN (SELECT COUNT (*) FROM SelectionOutput.AdhocSelection_OnlineOutput) > 0 THEN (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Authorised')
													ELSE (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Selected')
											END,
				DateLastRun				= GETDATE(),
				RecordsSelected			= (SELECT COUNT (*) FROM SelectionOutput.AdhocSelection_OnlineOutput)
		WHERE	RequirementID = @SelectionRequirementID

	COMMIT TRANSACTION
	
    END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH