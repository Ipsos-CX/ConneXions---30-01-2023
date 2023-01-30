CREATE PROCEDURE CRCNonSolicitation.uspGetCRCNonSolicitations

AS

/*
	Purpose:	Gets all non solicitations and loads them into tables for output
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	-- DON'T BOTHER WITH EVENT NON SOLICITATIONS AS THESE ARE EVENT SPECIFIC


	-- GET ALL PARTY NON SOLICITATIONS
	INSERT INTO CRCNonSolicitation.PartyNonSolicitations
	(
		 PartyID
		,NonSolicitationText
	)
	SELECT DISTINCT
		 NS.PartyID
		,NST.NonSolicitationText
	FROM [$(SampleDB)].dbo.NonSolicitations NS
	INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NST ON NST.NonSolicitationTextID = NS.NonSolicitationTextID
	INNER JOIN [$(SampleDB)].Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
	WHERE NS.ThroughDate IS NULL


	-- GET THE CURRENT CONTACT DETAILS FOR EACH OF THE PARTIES
	INSERT INTO CRCNonSolicitation.PartyNonSolicitationData
	(
		 PartyID
		,NonSolicitationText
	)
	SELECT 
		 PartyID
		,NonSolicitationText
	FROM CRCNonSolicitation.PartyNonSolicitations
	ORDER BY PartyID

	-- GET THE LATEST VIN ASSOCIATED WITH EACH PARTY
	UPDATE D
	SET  D.VehicleID = V.VehicleID
		,D.VIN = V.VIN
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN (	
		SELECT
			 PNS.PartyID
			,MAX(VPR.FromDate) AS LatestVINDate
		FROM CRCNonSolicitation.PartyNonSolicitations PNS
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = PNS.PartyID AND VPR.ThroughDate IS NULL
		GROUP BY PNS.PartyID
	) LV ON LV.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = LV.PartyID AND VPR.FromDate = LV.LatestVINDate
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = VPR.VehicleID

	-- GET THE PEOPLE DETAIL
	UPDATE D
	SET  D.Title = T.Title
		,D.FirstName = P.FirstName
		,D.MiddleName = P.MiddleName
		,D.LastName = P.LastName
		,D.SecondLastName = P.SecondLastName
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = P.TitleID

	-- GET THE ORGANISATION NAME FOR ORGANISATION ONLY PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = D.PartyID

	-- GET THE ORGANISATION NAME FOR PEOPLE PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = PR.PartyIDTo
	WHERE D.OrganisationName IS NULL


	-- NOW GET THE PARTY BEST POSTAL ADDRESS VALUES
	UPDATE D
	SET  D.PostalContactMechanismID = PA.ContactMechanismID
		,D.BuildingName = PA.BuildingName
		,D.SubStreet = PA.SubStreet
		,D.Street = PA.Street
		,D.SubLocality = PA.SubLocality
		,D.Locality = PA.Locality
		,D.Town = PA.Town
		,D.Region = PA.Region
		,D.PostCode = PA.PostCode
		,D.Country = PA.Country
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN (
		SELECT
			PCM.PartyID, 
			MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON CM.ContactMechanismID = PA.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID 
			FROM [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMNS ON PCM.PartyID = CMNS.PartyID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID
			FROM [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
		WHERE CMNS.PartyID IS NULL
		AND CMTNS.PartyID IS NULL
		AND CM.Valid = 1
		AND CASE C.Country
				WHEN 'Italy' THEN NULLIF(RTRIM(LTRIM(Street)), '')
				ELSE ''
		END IS NOT NULL
		GROUP BY PCM.PartyID
	) PBPA ON PBPA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID

	-- NOW GET THE PARTY BEST EMAIL VALUES
	UPDATE D
	SET  D.EmailContactMechanismID = EA.ContactMechanismID
		,D.Email = EA.EmailAddress
	FROM CRCNonSolicitation.PartyNonSolicitationData D
	INNER JOIN (
		SELECT
			 PCM.PartyID
			,MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN (
			SELECT
				 MAX(PCM.FromDate) AS FromDate
				,PCM.PartyID
			FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA on CM.ContactMechanismID = EA.ContactMechanismID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID 
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON CMNS.ContactMechanismID = EA.ContactMechanismID
				WHERE GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMNS ON PCM.PartyID = CMNS.PartyID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
				WHERE CMT.ContactMechanismType = 'E-mail address'
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
			WHERE CM.Valid = 1
			AND CMNS.PartyID IS NULL
			AND CMTNS.PartyID IS NULL
			GROUP BY PCM.PartyID
		) EA ON EA.FromDate = PCM.FromDate AND EA.PartyID = PCM.PartyID
		GROUP BY PCM.PartyID
	) PBEA ON PBEA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PBEA.ContactMechanismID






	-- GET ALL POSTAL CONTACT MECHANISM NON SOLICITATIONS
	INSERT INTO CRCNonSolicitation.PostalContactMechanismNonSolicitations
	(
		 PartyID
		,NonSolicitationText
		,ContactMechanismID
	)
	SELECT DISTINCT
		 NS.PartyID
		,NST.NonSolicitationText
		,CMNS.ContactMechanismID
	FROM [$(SampleDB)].dbo.NonSolicitations NS
	INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NST ON NST.NonSolicitationTextID = NS.NonSolicitationTextID
	INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
	INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CMNS.ContactMechanismID
	WHERE NS.ThroughDate IS NULL


	-- INSERT THE NON SOLICITATION DATA
	INSERT INTO CRCNonSolicitation.PostalContactMechanismNonSolicitationData
	(
		 PartyID
		,NonSolicitationText
		,NonSolicitedPostalContactMechanismID
	)
	SELECT 
		 PartyID
		,NonSolicitationText
		,ContactMechanismID
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitations
	ORDER BY PartyID

	-- GET THE LATEST VIN ASSOCIATED WITH EACH PARTY
	UPDATE D
	SET  D.VehicleID = V.VehicleID
		,D.VIN = V.VIN
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN (	
		SELECT
			 CMNS.PartyID
			,MAX(VPR.FromDate) AS LatestVINDate
		FROM CRCNonSolicitation.PostalContactMechanismNonSolicitations CMNS
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = CMNS.PartyID AND VPR.ThroughDate IS NULL
		GROUP BY CMNS.PartyID
	) LV ON LV.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = LV.PartyID AND VPR.FromDate = LV.LatestVINDate
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = VPR.VehicleID

	-- GET THE PEOPLE DETAIL
	UPDATE D
	SET  D.Title = T.Title
		,D.FirstName = P.FirstName
		,D.MiddleName = P.MiddleName
		,D.LastName = P.LastName
		,D.SecondLastName = P.SecondLastName
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = P.TitleID

	-- GET THE ORGANISATION NAME FOR ORGANISATION ONLY PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = D.PartyID

	-- GET THE ORGANISATION NAME FOR PEOPLE PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = PR.PartyIDTo
	WHERE D.OrganisationName IS NULL


	-- NOW GET THE PARTY BEST POSTAL ADDRESS VALUES
	UPDATE D
	SET  D.CurrentPostalContactMechanismID = PA.ContactMechanismID
		,D.CurrentBuildingName = PA.BuildingName
		,D.CurrentSubStreet = PA.SubStreet
		,D.CurrentStreet = PA.Street
		,D.CurrentSubLocality = PA.SubLocality
		,D.CurrentLocality = PA.Locality
		,D.CurrentTown = PA.Town
		,D.CurrentRegion = PA.Region
		,D.CurrentPostCode = PA.PostCode
		,D.CurrentCountry = PA.Country
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN (
		SELECT
			PCM.PartyID, 
			MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON CM.ContactMechanismID = PA.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID 
			FROM [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMNS ON PCM.PartyID = CMNS.PartyID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID
			FROM  [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
		WHERE CMNS.PartyID IS NULL
		AND CMTNS.PartyID IS NULL
		AND CM.Valid = 1
		AND CASE C.Country
				WHEN 'Italy' THEN NULLIF(RTRIM(LTRIM(Street)), '')
				ELSE ''
		END IS NOT NULL
		GROUP BY PCM.PartyID
	) PBPA ON PBPA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID

	-- NOW GET THE PARTY BEST EMAIL VALUES
	UPDATE D
	SET  D.CurrentEmailContactMechanismID = EA.ContactMechanismID
		,D.CurrentEmail = EA.EmailAddress
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN (
		SELECT
			 PCM.PartyID
			,MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN (
			SELECT
				 MAX(PCM.FromDate) AS FromDate
				,PCM.PartyID
			FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA on CM.ContactMechanismID = EA.ContactMechanismID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID 
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON CMNS.ContactMechanismID = EA.ContactMechanismID
				WHERE GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMNS ON PCM.PartyID = CMNS.PartyID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
				WHERE CMT.ContactMechanismType = 'E-mail address'
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
			WHERE CM.Valid = 1
			AND CMNS.PartyID IS NULL
			AND CMTNS.PartyID IS NULL
			GROUP BY PCM.PartyID
		) EA ON EA.FromDate = PCM.FromDate AND EA.PartyID = PCM.PartyID
		GROUP BY PCM.PartyID
	) PBEA ON PBEA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PBEA.ContactMechanismID

	-- GET THE NON SOLICITED ADDRESS DETAILS
	UPDATE D
	SET  D.NonSolicitedPostalContactMechanismID = PA.ContactMechanismID
		,D.NonSolicitedBuildingName = PA.BuildingName
		,D.NonSolicitedSubStreet = PA.SubStreet
		,D.NonSolicitedStreet = PA.Street
		,D.NonSolicitedSubLocality = PA.SubLocality
		,D.NonSolicitedLocality = PA.Locality
		,D.NonSolicitedTown = PA.Town
		,D.NonSolicitedRegion = PA.Region
		,D.NonSolicitedPostCode = PA.PostCode
		,D.NonSolicitedCountry = PA.Country
	FROM CRCNonSolicitation.PostalContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = D.NonSolicitedPostalContactMechanismID









	-- GET ALL EMAIL CONTACT MECHANISM NON SOLICITATIONS
	INSERT INTO CRCNonSolicitation.EmailContactMechanismNonSolicitations
	(
		 PartyID
		,NonSolicitationText
		,ContactMechanismID
	)
	SELECT DISTINCT
		 NS.PartyID
		,NST.NonSolicitationText
		,CMNS.ContactMechanismID
	FROM [$(SampleDB)].dbo.NonSolicitations NS
	INNER JOIN [$(SampleDB)].dbo.NonSolicitationTexts NST ON NST.NonSolicitationTextID = NS.NonSolicitationTextID
	INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CMNS.ContactMechanismID
	WHERE NS.ThroughDate IS NULL


	-- GET THE CURRENT CONTACT DETAILS FOR EACH OF THE PARTIES AS WELL AS THE NON SOLICITED EMAIL
	-- INSERT THE NON SOLICITATION DATA
	INSERT INTO CRCNonSolicitation.EmailContactMechanismNonSolicitationData
	(
		 PartyID
		,NonSolicitationText
		,NonSolicitedEmailContactMechanismID
	)
	SELECT 
		 PartyID
		,NonSolicitationText
		,ContactMechanismID
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitations
	ORDER BY PartyID

	-- GET THE LATEST VIN ASSOCIATED WITH EACH PARTY
	UPDATE D
	SET  D.VehicleID = V.VehicleID
		,D.VIN = V.VIN
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN (	
		SELECT
			 CMNS.PartyID
			,MAX(VPR.FromDate) AS LatestVINDate
		FROM CRCNonSolicitation.EmailContactMechanismNonSolicitations CMNS
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = CMNS.PartyID AND VPR.ThroughDate IS NULL
		GROUP BY CMNS.PartyID
	) LV ON LV.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = LV.PartyID AND VPR.FromDate = LV.LatestVINDate
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON V.VehicleID = VPR.VehicleID

	-- GET THE PEOPLE DETAIL
	UPDATE D
	SET  D.Title = T.Title
		,D.FirstName = P.FirstName
		,D.MiddleName = P.MiddleName
		,D.LastName = P.LastName
		,D.SecondLastName = P.SecondLastName
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Titles T ON T.TitleID = P.TitleID

	-- GET THE ORGANISATION NAME FOR ORGANISATION ONLY PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = D.PartyID

	-- GET THE ORGANISATION NAME FOR PEOPLE PARTIES
	UPDATE D
	SET D.OrganisationName = O.OrganisationName
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = D.PartyID
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = PR.PartyIDTo
	WHERE D.OrganisationName IS NULL


	-- NOW GET THE PARTY BEST POSTAL ADDRESS VALUES
	UPDATE D
	SET  D.CurrentPostalContactMechanismID = PA.ContactMechanismID
		,D.CurrentBuildingName = PA.BuildingName
		,D.CurrentSubStreet = PA.SubStreet
		,D.CurrentStreet = PA.Street
		,D.CurrentSubLocality = PA.SubLocality
		,D.CurrentLocality = PA.Locality
		,D.CurrentTown = PA.Town
		,D.CurrentRegion = PA.Region
		,D.CurrentPostCode = PA.PostCode
		,D.CurrentCountry = PA.Country
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN (
		SELECT
			PCM.PartyID, 
			MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON CM.ContactMechanismID = PA.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = PA.CountryID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID 
			FROM [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMNS ON PCM.PartyID = CMNS.PartyID
		LEFT JOIN (
			SELECT DISTINCT
				NS.PartyID
			FROM [$(SampleDB)].dbo.NonSolicitations NS
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
			WHERE CMT.ContactMechanismType = 'Postal Address'
			AND NS.ThroughDate IS NULL
		) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
		WHERE CMNS.PartyID IS NULL
		AND CMTNS.PartyID IS NULL
		AND CM.Valid = 1
		AND CASE C.Country
				WHEN 'Italy' THEN NULLIF(RTRIM(LTRIM(Street)), '')
				ELSE ''
		END IS NOT NULL
		GROUP BY PCM.PartyID
	) PBPA ON PBPA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwPostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID

	-- NOW GET THE PARTY BEST EMAIL VALUES
	UPDATE D
	SET  D.CurrentEmailContactMechanismID = EA.ContactMechanismID
		,D.CurrentEmail = EA.EmailAddress
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN (
		SELECT
			 PCM.PartyID
			,MAX(PCM.ContactMechanismID) AS ContactMechanismID
		FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN (
			SELECT
				 MAX(PCM.FromDate) AS FromDate
				,PCM.PartyID
			FROM [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA on CM.ContactMechanismID = EA.ContactMechanismID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID 
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON CMNS.ContactMechanismID = EA.ContactMechanismID
				WHERE GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMNS ON PCM.PartyID = CMNS.PartyID
			LEFT JOIN (
				SELECT DISTINCT
					NS.PartyID
				FROM [$(SampleDB)].dbo.NonSolicitations NS
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
				INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CMTNS.ContactMechanismTypeID
				WHERE CMT.ContactMechanismType = 'E-mail address'
				AND GETDATE() >= NS.FromDate
				AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
			) AS CMTNS ON PCM.PartyID = CMTNS.PartyID
			WHERE CM.Valid = 1
			AND CMNS.PartyID IS NULL
			AND CMTNS.PartyID IS NULL
			GROUP BY PCM.PartyID
		) EA ON EA.FromDate = PCM.FromDate AND EA.PartyID = PCM.PartyID
		GROUP BY PCM.PartyID
	) PBEA ON PBEA.PartyID = D.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = PBEA.ContactMechanismID

	-- GET THE NON SOLICITED EMAIL DETAILS
	UPDATE D
	SET  D.NonSolicitedEmailContactMechanismID = EA.ContactMechanismID
		,D.NonSolicitedEmail = EA.EmailAddress
	FROM CRCNonSolicitation.EmailContactMechanismNonSolicitationData D
	INNER JOIN [$(SampleDB)].ContactMechanism.vwEmailAddresses EA ON EA.ContactMechanismID = D.NonSolicitedEmailContactMechanismID



END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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