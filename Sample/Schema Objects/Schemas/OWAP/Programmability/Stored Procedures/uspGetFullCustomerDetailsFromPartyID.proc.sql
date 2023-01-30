CREATE PROCEDURE [OWAP].[uspGetFullCustomerDetailsFromPartyID]
    @PartyID [dbo].[PartyID] ,
    @CaseID [dbo].[CaseID] = NULL ,   --Version: 2.0 change
    @RowCount INT = NULL OUTPUT , --Version: 2.0 change
    @ErrorCode INT = NULL OUTPUT --Version: 2.0 change
AS

/*
Version: 2.0
Date:22-Dec-2014
Changed by:Peter Doyle
Reason: Non-solicitations not showing correctly for email and address and telephone
Where changed:  Search for "Version: 2.0 change"
--
also added defaults to parameters to help testing

		
test code
--[OWAP].[uspGetFullCustomerDetailsFromPartyID] @PartyID = 13924819
--[OWAP].[uspGetFullCustomerDetailsFromPartyID] @PartyID = 13929474
--[OWAP].[uspGetFullCustomerDetailsFromPartyID] @PartyID = 11161295
--[OWAP].[uspGetFullCustomerDetailsFromPartyID] @PartyID = 9627993

*/



    SET NOCOUNT ON

    DECLARE @ErrorNumber INT
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @ErrorLocation NVARCHAR(500)
    DECLARE @ErrorLine INT
    DECLARE @ErrorMessage NVARCHAR(2048)

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

	-- GET THE EMPLOYEE AND EMPLOYER ROLE TYPES
        DECLARE @EmployerRoleTypeID dbo.RoleTypeID
        DECLARE @EmployeeRoleTypeID dbo.RoleTypeID

        SELECT  @EmployerRoleTypeID = RoleTypeID
        FROM    dbo.RoleTypes
        WHERE   RoleType = 'Employer'
        SELECT  @EmployeeRoleTypeID = RoleTypeID
        FROM    dbo.RoleTypes
        WHERE   RoleType = 'Employee'


	-- GET THE CUSTOMER DETAILS
        SELECT DISTINCT
                P.PartyID ,
                COALESCE(T.TitleID, T_O.TitleID, '') AS TitleID ,
                COALESCE(T.Title, T_O.Title, '') AS Title ,
                COALESCE(PP.FirstName, PP_O.FirstName, '') AS FirstName ,
                COALESCE(PP.Initials, PP_O.Initials, '') AS Initials ,
                COALESCE(PP.MiddleName, PP_O.MiddleName, '') AS MiddleName ,
                COALESCE(PP.LastName, PP_O.LastName, '') AS LastName ,
                COALESCE(PP.SecondLastName, PP_O.SecondLastName, '') AS SecondLastName ,
                COALESCE(CONVERT(NVARCHAR(24), PP.BirthDate, 103),
                         CONVERT(NVARCHAR(24), PP_O.BirthDate, 103), '') AS BirthDate ,
                COALESCE(G.GenderID, G_O.GenderID, '') AS GenderID ,
                COALESCE(G.Gender, G_O.Gender, '') AS Gender ,
                COALESCE(O.OrganisationName, O_PP.OrganisationName, '') AS OrganisationName ,
                CASE WHEN PP.PartyID IS NOT NULL THEN 'P'
                     WHEN O.PartyID IS NOT NULL THEN 'O'
                END AS PersonOrganisation ,
                L.LanguageID ,
                L.Language ,
                CASE WHEN NS.NonSolicitationID IS NOT NULL THEN 'Yes'
                     ELSE 'No'
                END AS PartyNonSolicitation
        FROM    Party.Parties P
                LEFT JOIN Party.People PP
                INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = P.PartyID
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
                INNER JOIN Party.Titles T_O ON T_O.TitleID = PP_O.TitleID
                LEFT JOIN Party.Genders G_O ON G_O.GenderID = PP_O.GenderID ON PR_O.PartyIDTo = O.PartyID
                LEFT JOIN Party.PartyLanguages PL
                INNER JOIN dbo.Languages L ON L.LanguageID = PL.LanguageID
                                              AND PL.PreferredFlag = 1 ON PL.PartyID = P.PartyID
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
                ISNULL(COT.CaseOutputType, N'')
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
                                                              AND AEBI.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
        WHERE   VPRE.PartyID = @PartyID
        ORDER BY EventDate DESC

    END TRY
    BEGIN CATCH

        SET @ErrorCode = @@Error

        SELECT  @ErrorNumber = ERROR_NUMBER() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ,
                @ErrorLocation = ERROR_PROCEDURE() ,
                @ErrorLine = ERROR_LINE() ,
                @ErrorMessage = ERROR_MESSAGE()

        EXEC [Sample_Errors].dbo.uspLogDatabaseError @ErrorNumber,
            @ErrorSeverity, @ErrorState, @ErrorLocation, @ErrorLine,
            @ErrorMessage
		
        RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
    END CATCH


GO

