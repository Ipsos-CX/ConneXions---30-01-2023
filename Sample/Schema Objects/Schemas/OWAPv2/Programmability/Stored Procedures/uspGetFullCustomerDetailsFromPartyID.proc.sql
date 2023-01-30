CREATE PROCEDURE [OWAPv2].[uspGetFullCustomerDetailsFromPartyID]
@PartyID [dbo].[PartyID], @CaseID [dbo].[CaseID]=NULL,@AuditItemID [dbo].[AuditItemID]=NULL, @RowCount INT=NULL OUTPUT, @ErrorCode INT=NULL OUTPUT, @PartyIDType INT=0 OUTPUT
AS
SET NOCOUNT ON

    DECLARE @ErrorNumber INT
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @ErrorLocation NVARCHAR(500)
    DECLARE @ErrorLine INT
    DECLARE @ErrorMessage NVARCHAR(2048)

/*
	Purpose:	Returns the dataset for customer based on Country, Region and PostCode
		
	Version			Date			Developer			Comment
	1.0				?				?					Created
	1.1				10/05/2018		Chris Ross			BUG 14399 - Add in filters to ensure details not returned for GDPR erased but "[GDPR - Erased]" text on 
																	Firstname and Lastname.  Also stop zero value dupes appearing for Cases.
	1.2				13/07/2018		Chris Ledger		SELECT TYPE OF NON-SOLICITATION (GDPR)
	1.3				18/07/2018		Ben King			BUG 14838
	1.4				18/10/2019		Ben King			BUG 16661 - add audititem id to parameters
*/	



    BEGIN TRY

        SET @ErrorCode = 0
        SET @RowCount = 0
	
		-- IF WE'VE NOT GOT A PARTYID BUT HAVE GOT A CASEID GET THE PARTYID FROM THE CASEID
		-- OTHERWISE WE USE THE SUPPLIED PARTYID
        IF ( ( ( @PartyID IS NULL )
               OR ( @PartyID = 0 )
             )
             AND @CaseID IS NOT NULL
           )
            BEGIN
                SELECT  @PartyID = PartyID
                FROM    Event.AutomotiveEventBasedInterviews
                WHERE   CaseID = @CaseID
            END
        
		--V1.4 
		IF ( ( ( @PartyID IS NULL )
               OR ( @PartyID = 0 )
             )
             AND @AuditItemID IS NOT NULL
           )
            BEGIN
                SELECT  @PartyID = MatchedODSPersonID
                FROM    [$(WebsiteReporting)].[dbo].[SampleQualityAndSelectionLogging]
                WHERE   [AuditItemID] = @AuditItemID
            END


		-- Set GDPR Name column if the PartyID has had a GDPR Erase request					-- v1.1
		DECLARE @GDPRName NVARCHAR(50)
		SELECT @GDPRName = '[GDPR - Erased]'
		FROM [$(AuditDB)].GDPR.ErasureRequests WHERE PartyID = @PartyID


		-- GET THE EMPLOYEE AND EMPLOYER ROLE TYPES
        DECLARE @EmployerRoleTypeID dbo.RoleTypeID
        DECLARE @EmployeeRoleTypeID dbo.RoleTypeID

        SELECT  @EmployerRoleTypeID = RoleTypeID
        FROM    dbo.RoleTypes
        WHERE   RoleType = 'Employer'
        SELECT  @EmployeeRoleTypeID = RoleTypeID
        FROM    dbo.RoleTypes
        WHERE   RoleType = 'Employee'


		--DETERMINE PARTYTYPE
		SELECT		@PartyIDType = CASE
										WHEN pp.PartyID IS NOT NULL THEN 0		--PERSON
										WHEN og.PartyID IS NOT NULL THEN 1		--ORGANISATION
										ELSE NULL
								   END
		FROM		Party.Parties		p
		LEFT JOIN	Party.People		pp ON P.PartyID = pp.PartyID
		LEFT JOIN 	Party.Organisations og ON P.PartyID = OG.PartyID

		WHERE		P.PartyID = @PartyID


		-- GET THE CUSTOMER DETAILS
        SELECT DISTINCT
                P.PartyID ,
                COALESCE(T.TitleID, T_O.TitleID, '') AS TitleID ,
                COALESCE(T.Title, T_O.Title, '') AS Title ,
                COALESCE(@GDPRName, PP.FirstName, PP_O.FirstName, '') AS FirstName ,				-- v1.1
                COALESCE(PP.Initials, PP_O.Initials, '') AS Initials ,
                COALESCE(PP.MiddleName, PP_O.MiddleName, '') AS MiddleName ,
                COALESCE(@GDPRName, PP.LastName, PP_O.LastName, '') AS LastName ,					-- v1.1
                COALESCE(PP.SecondLastName, PP_O.SecondLastName, '') AS SecondLastName ,
                COALESCE(CONVERT(NVARCHAR(24), PP.BirthDate, 103),
                         CONVERT(NVARCHAR(24), PP_O.BirthDate, 103), '') AS BirthDate ,
                COALESCE(G.GenderID, G_O.GenderID, '') AS GenderID ,
                COALESCE(G.Gender, G_O.Gender, '') AS Gender ,
                COALESCE(O.OrganisationName, O_PP.OrganisationName, '') AS OrganisationName ,
                CASE WHEN PP.PartyID IS NOT NULL THEN 'P'
                     WHEN O.PartyID IS NOT NULL THEN 'O'
 					 ELSE ''																		-- v1.1
                END AS PersonOrganisation ,
                ISNULL(L.LanguageID, 0) AS LanguageID ,												-- v1.1
                ISNULL(L.Language, '') AS Language,													-- v1.1
                CASE WHEN NS.NonSolicitationID IS NOT NULL THEN
						------------------------------------------------------------------------------------------------------------
						-- V1.2 SELECT TYPE OF NON-SOLICITATION (GDPR)
						-----------------------------------------------------------------------------------------------------------
						(SELECT TOP 1 CASE	WHEN NST.NonSolicitationText = 'GDPR Right to Erasure' THEN 
									(SELECT CASE ER.FullErasure WHEN 'Y' THEN 'GDPR Erasure (Full)'
																WHEN 'N' THEN 'GDPR Erasure (Partial)' END 
												FROM [$(AuditDB)].GDPR.ErasureRequests ER WHERE ER.AuditID = MAX(AI.AuditID)
																								AND NS.PartyID = ER.PartyID)
								WHEN NST.NonSolicitationText = 'GDPR Right to Restriction' THEN 'GDPR Right to Restriction'
								ELSE 'Yes'
						END AS NonSolicitation
						FROM dbo.NonSolicitations NS
						LEFT JOIN dbo.NonSolicitationTexts NST ON NST.NonSolicitationTextID = NS.NonSolicitationTextID
						INNER JOIN Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID													
																AND ISNULL(NS.FromDate, '1 Jan 1900') < GETDATE()
																AND ISNULL(NS.ThroughDate, '31 Dec 9999') > GETDATE() 
						LEFT JOIN [$(AuditDB)].Audit.NonSolicitations ANS ON NS.NonSolicitationID = ANS.NonSolicitationID
																				AND NS.PartyID = ANS.PartyID
						LEFT JOIN [$(AuditDB)].dbo.AuditItems AI ON ANS.AuditItemID = AI.AuditItemID
						LEFT JOIN [$(AuditDB)].GDPR.ErasureRequests ER ON AI.AuditID = ER.AuditID
																			AND NS.PartyID = ER.PartyID
						WHERE NS.PartyID = @PartyID
						GROUP BY NS.PartyID, NST.NonSolicitationText
						ORDER BY NonSolicitation)
 						-----------------------------------------------------------------------------------------------------------
                    ELSE 'No'
                END AS PartyNonSolicitation
        FROM    Party.Parties P
				LEFT JOIN Party.People PP
						INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID 
					ON PP.PartyID = P.PartyID AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
																WHERE er.PartyID = PP.PartyID)
                LEFT JOIN Party.Genders G ON G.GenderID = PP.GenderID
                LEFT JOIN Party.Organisations O ON O.PartyID = P.PartyID
		-- FOR A PERSON PARTY GET ANY RELATED ORGANISATION
                LEFT JOIN Party.PartyRelationships PR_PP
                INNER JOIN Party.Organisations O_PP ON O_PP.PartyID = PR_PP.PartyIDTo
                                                       AND PR_PP.RoleTypeIDFrom = @EmployeeRoleTypeID
                                                       AND PR_PP.RoleTypeIDTo = @EmployerRoleTypeID ON PR_PP.PartyIDFrom = PP.PartyID
		-- FOR AN ORGANISATION PARTY GET ANY RELATED EMPLOYEE
                LEFT JOIN Party.PartyRelationships PR_O
                INNER JOIN Party.People PP_O ON PP_O.PartyID = PR_O.PartyIDFrom
                                                AND PR_O.RoleTypeIDFrom = @EmployeeRoleTypeID
                                                AND PR_O.RoleTypeIDTo = @EmployerRoleTypeID
												AND NOT EXISTS (SELECT er2.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er2			-- v1.1
																WHERE er2.PartyID = PP_O.PartyID)
                INNER JOIN Party.Titles T_O ON T_O.TitleID = PP_O.TitleID
                LEFT JOIN Party.Genders G_O ON G_O.GenderID = PP_O.GenderID ON PR_O.PartyIDTo = O.PartyID
                LEFT JOIN Party.PartyLanguages PL
                INNER JOIN dbo.Languages L ON L.LanguageID = PL.LanguageID
                                              AND PL.PreferredFlag = 1 ON PL.PartyID = P.PartyID
											  AND NOT EXISTS (SELECT er3.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er3			-- v1.1
																WHERE er3.PartyID = P.PartyID)
                LEFT JOIN dbo.NonSolicitations NS
                INNER JOIN Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
														
                                                         AND ISNULL(NS.FromDate,
                                                              '1 Jan 1900') < GETDATE()
                                                         AND ISNULL(NS.ThroughDate,
                                                              '31 Dec 9999') > GETDATE() ON NS.PartyID = P.PartyID
        WHERE   P.PartyID = @PartyID
	
		-- SET THE ROW COUNT TO BE THE NUMBER OF ROWS RETURNED FOR THE PARTY
        SET @RowCount = @@ROWCOUNT

		-- GET THE POSTAL ADDRESS DETAILS
        SELECT DISTINCT
                PA.ContactMechanismID ,
                PA.BuildingName ,
                PA.SubStreetNumber ,
                PA.SubStreet ,
                PA.StreetNumber ,
                PA.Street ,
                PA.SubLocality ,
                PA.Locality ,
                PA.Town ,
                PA.Region ,
                PA.PostCode ,
                C.CountryID ,
                C.Country ,
                CASE WHEN NS.NonSolicitationID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS AddressNonSolicitation ,
                CASE WHEN PBPA.PartyID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS PartyBestPostalAddress
        FROM    ContactMechanism.PartyContactMechanisms PCM
                INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM.ContactMechanismID
                INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
                LEFT JOIN dbo.NonSolicitations NS
                INNER JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
																-- begin Version: 2.0 change	
                                                              AND ISNULL(NS.FromDate,
                                                              '1 Jan 1900') < GETDATE()
                                                              AND ISNULL(NS.ThroughDate,
                                                              '31 Dec 9999') > GETDATE() ON NS.PartyID = PCM.PartyID
															  -- end Version: 2.0 change  (there are others)
                                                              AND CMNS.ContactMechanismID = PA.ContactMechanismID
                LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PCM.PartyID
                                                              AND PBPA.ContactMechanismID = PCM.ContactMechanismID
        WHERE   PCM.PartyID = @PartyID
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
											WHERE er.PartyID = PCM.PartyID)
        ORDER BY PA.ContactMechanismID

		-- GET THE TELEPHONE NUMBERS
        SELECT DISTINCT
                PCM.ContactMechanismID ,
                TN.ContactNumber ,
                CMT.ContactMechanismType ,
                CASE WHEN NS.NonSolicitationID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS TelephoneNonSolicitation ,
                CASE WHEN PBTN_HOME.PartyID IS NOT NULL THEN 'Yes'
                     WHEN PBTN_LAND.PartyID IS NOT NULL THEN 'Yes'
                     WHEN PBTN_MOB.PartyID IS NOT NULL THEN 'Yes'
                     WHEN PBTN_PHONE.PartyID IS NOT NULL THEN 'Yes'
                     WHEN PBTN_WORK.PartyID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS PartyBestTelephoneNumbers
        FROM    ContactMechanism.PartyContactMechanisms PCM
                INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = PCM.ContactMechanismID
                INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = TN.ContactMechanismID
                INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID
                LEFT JOIN dbo.NonSolicitations NS
                INNER JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID ON NS.PartyID = PCM.PartyID
																-- begin Version: 2.0 change
                                                              AND ISNULL(NS.FromDate,
                                                              '1 Jan 1900') < GETDATE()
                                                              AND ISNULL(NS.ThroughDate,
                                                              '31 Dec 9999') > GETDATE()
															  -- end Version: 2.0 change
                                                              AND CMNS.ContactMechanismID = TN.ContactMechanismID
                LEFT JOIN Meta.PartyBestTelephoneNumbers PBTN_HOME ON PBTN_HOME.PartyID = PCM.PartyID
                                                              AND PBTN_HOME.HomeLandlineID = PCM.ContactMechanismID
                LEFT JOIN Meta.PartyBestTelephoneNumbers PBTN_LAND ON PBTN_LAND.PartyID = PCM.PartyID
                                                              AND PBTN_LAND.LandlineID = PCM.ContactMechanismID
                LEFT JOIN Meta.PartyBestTelephoneNumbers PBTN_MOB ON PBTN_MOB.PartyID = PCM.PartyID
                                                              AND PBTN_MOB.MobileID = PCM.ContactMechanismID
                LEFT JOIN Meta.PartyBestTelephoneNumbers PBTN_PHONE ON PBTN_PHONE.PartyID = PCM.PartyID
                                                              AND PBTN_PHONE.PhoneID = PCM.ContactMechanismID
                LEFT JOIN Meta.PartyBestTelephoneNumbers PBTN_WORK ON PBTN_WORK.PartyID = PCM.PartyID
                                                              AND PBTN_WORK.WorkLandlineID = PCM.ContactMechanismID
        WHERE   PCM.PartyID = @PartyID
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
											WHERE er.PartyID = PCM.PartyID)
        ORDER BY PCM.ContactMechanismID

		-- GET THE EMAIL ADDRESSES
        SELECT  PCM.ContactMechanismID ,
                EA.EmailAddress ,
                CASE WHEN NS.NonSolicitationID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS EmailNonSolicitation ,
                CASE WHEN PBEA.PartyID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS PartyBestEmailAddress
        FROM    ContactMechanism.PartyContactMechanisms PCM
                INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PCM.ContactMechanismID
                LEFT JOIN dbo.NonSolicitations NS
                INNER JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID ON NS.PartyID = PCM.PartyID
																-- begin Version: 2.0 change
                                                              AND ISNULL(NS.FromDate,
                                                              '1 Jan 1900') < GETDATE()
                                                              AND ISNULL(NS.ThroughDate,
                                                              '31 Dec 9999') > GETDATE()
															  -- end Version: 2.0 change
                                                              AND CMNS.ContactMechanismID = EA.ContactMechanismID
                LEFT JOIN Meta.PartyBestEmailAddresses PBEA ON PBEA.PartyID = PCM.PartyID
                                                              AND PBEA.ContactMechanismID = PCM.ContactMechanismID
        WHERE   PCM.PartyID = @PartyID
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
											WHERE er.PartyID = PCM.PartyID)
        ORDER BY PCM.ContactMechanismID

		-- GET EVENTS AN VEHICLES
        SELECT DISTINCT
                E.EventID ,
                CONVERT(NVARCHAR(24), E.EventDate, 103) AS EventDate ,
                ET.EventType ,
                V.VehicleID ,
                V.VIN ,
                ISNULL(V.VINPrefix, N'') ,
                ISNULL(V.ChassisNumber, N'') ,
                M.ModelDescription ,
                R.RegistrationID ,
                R.RegistrationNumber ,
                CONVERT(NVARCHAR(24), R.RegistrationDate, 103) AS RegistrationDate ,
                D.Outlet AS DealerName ,
                D.OutletCode AS DealerCode ,
                ISNULL(C.CaseID, N'') ,
                ISNULL(CST.CaseStatusType, N'') ,
                ISNULL(CONVERT(NVARCHAR(24), C.CreationDate, 103), N'') AS CaseCreationDate ,
                ISNULL(CONVERT(NVARCHAR(24), C.ClosureDate, 103), N'') AS CaseClosureDate ,
                ISNULL(S.Requirement, N'') AS Selection ,
                ISNULL(COT.CaseOutputType, N''),
				ISNULL(F.FileName,N'') AS FileName

        FROM    Vehicle.VehiclePartyRoleEvents VPRE
                INNER JOIN Vehicle.Vehicles V ON V.VehicleID = VPRE.VehicleID
                INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
                INNER JOIN Event.Events E ON E.EventID = VPRE.EventID
                INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
                LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
                INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID ON VRE.EventID = VPRE.EventID
                                                              AND VRE.VehicleID = VPRE.VehicleID
                LEFT JOIN Event.EventPartyRoles EPR
                INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID
                                                     AND D.OutletFunctionID = EPR.RoleTypeID ON EPR.EventID = E.EventID
                LEFT JOIN Event.AutomotiveEventBasedInterviews AEBI
                INNER JOIN Event.Cases C ON C.CaseID = AEBI.CaseID
                INNER JOIN Event.CaseStatusTypes CST ON CST.CaseStatusTypeID = C.CaseStatusTypeID
                INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = C.CaseID
                INNER JOIN Requirement.Requirements S ON S.RequirementID = SC.RequirementIDPartOf
                LEFT JOIN Event.CaseOutput CO
                INNER JOIN Event.CaseOutputTypes COT ON COT.CaseOutputTypeID = CO.CaseOutputTypeID ON CO.CaseID = C.CaseID ON AEBI.EventID = E.EventID
                                                              AND AEBI.PartyID = VPRE.PartyID
                                                              AND AEBI.VehicleID = VPRE.VehicleID
                                                           -- v1.1 -- AND AEBI.VehicleRoleTypeID = VPRE.VehicleRoleTypeID    -- Removes dupes because of DISTINCT in SELECT
				LEFT JOIN [$(AuditDB)].Audit.Events AE  ON E.EventID = AE.EventID
				LEFT JOIN [$(AuditDB)].dbo.AuditItems AI ON AE.AuditItemID  = AI.AuditItemID
				LEFT JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID

        WHERE   VPRE.PartyID = @PartyID
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
											WHERE er.PartyID = VPRE.PartyID)
        ORDER BY EventDate DESC

	--V1.3 GET ADDITIONAL INFO TAB
		  SELECT DISTINCT
                E.EventID ,
                CASE
					WHEN ET.EventType = 'Sales' AND AIF.SalesAdvisorName  IS NULL THEN AIF.Salesman
					WHEN ET.EventType <> 'Sales' THEN ''
					ELSE AIF.SalesAdvisorName
				END AS Sales_Employee,
				CASE		
					WHEN ET.EventType IN ('Service','Bodyshop') AND DRS.AuditItemID IS NULL THEN AIF.Salesman 
					WHEN ET.EventType NOT IN ('Service','Bodyshop') THEN ''
					ELSE ''
				END AS Service_Employee,
				COALESCE(VCS.VISTACONTRACT_SALES_MAN_FULNAM, AIF.SalesAdvisorName,'') AS Salesman,
				COALESCE(DRS.[DMS_TECHNICIAN], AIF.TechnicianName,'') AS ServTech,

				 CASE
					WHEN ET.EventType = 'Sales' AND AIF.SalesmanCode IS NULL THEN VCS.VISTACONTRACT_SALESMAN_CODE
					WHEN ET.EventType <> 'Sales' THEN ''
					ELSE AIF.SalesmanCode
				END AS SalesManCD,
				
				CASE
					WHEN ET.EventType = 'Service' AND DRS.DMS_TECHNICIAN_ID IS NULL THEN AIF.TechnicianID
					WHEN ET.EventType <> 'Service' THEN ''
					ELSE DRS.DMS_TECHNICIAN_ID
				END AS ServTechCD,
				CASE
					WHEN ET.EventType = 'Service' AND DRS.DMS_SERVICE_ADVISOR IS NULL THEN AIF.ServiceAdvisorName
					WHEN ET.EventType <> 'Service' THEN ''
					ELSE DRS.DMS_SERVICE_ADVISOR
				END AS ServAdv,
				CASE
					WHEN ET.EventType = 'Service' AND DRS.DMS_SERVICE_ADVISOR_ID IS NULL THEN AIF.ServiceAdvisorID
					WHEN ET.EventType <> 'Service' THEN ''
					ELSE DRS.DMS_SERVICE_ADVISOR_ID
				END AS ServAdvCD,
								
				'' AS '10th col'

        FROM    Vehicle.VehiclePartyRoleEvents VPRE
                INNER JOIN Event.Events E ON E.EventID = VPRE.EventID
                INNER JOIN Event.EventTypes ET ON ET.EventTypeID = E.EventTypeID
				LEFT JOIN [$(AuditDB)].Audit.Events AE  ON E.EventID = AE.EventID
				LEFT JOIN [$(ETLDB)].[CRM].[DMS_Repair_Service] DRS ON DRS.AuditItemID = AE.AuditItemID 
				LEFT JOIN [$(AuditDB)].Audit.AdditionalInfoSales AIF ON AIF.AuditItemID = AE.AuditItemID
				LEFT JOIN [$(ETLDB)].[CRM].[Vista_Contract_Sales] VCS ON VCS.AuditItemID = AE.AuditItemID

        WHERE   VPRE.PartyID = @PartyID--@PartyID
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er			-- v1.1
											WHERE er.PartyID = VPRE.PartyID)
        ORDER BY E.Eventid DESC

    END TRY
    BEGIN CATCH

        SET @ErrorCode = @@Error

        SELECT  @ErrorNumber = ERROR_NUMBER() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ,
                @ErrorLocation = ERROR_PROCEDURE() ,
                @ErrorLine = ERROR_LINE() ,
                @ErrorMessage = ERROR_MESSAGE()

        EXEC [$(ErrorDB)].dbo.uspLogDatabaseError @ErrorNumber,
            @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
            @ErrorMessage
		
        RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
    END CATCH

