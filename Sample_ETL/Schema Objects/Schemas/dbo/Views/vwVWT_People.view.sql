
CREATE VIEW dbo.vwVWT_People

AS

/*
	Purpose:	List all People records currently in the VWT with checksums to identify similar addresses
				and People for use with deduping and matching routines.
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.vwVWT_People
	1.1			10/07/2012		Chris Ross			Added in Unique identifier into checksum for de-dupe of South 
													African customers.
	1.2			23-07-2012		Chris Ross			CustomerIdentifier to enable changes in [dbo].[uspVWT_DedupePeople]
													procedure work.														
	1.3			21-11-2013		Chris Ross			8967 - Add in EventTypeID so that we can identify Roadside records in the macthing proc's
	1.4			12-05-2014		Martin Riverol		10182 - Amend standard checksum algorithm
	1.5			01-12-2014		Chris Ross			11025 - Add in PartyMatchingMethodologyID, EmailAddress and PrivEmailAddress for matching on e	mail addresses
	1.6			13-06-2016		Eddie Thomas		12449 - Add in PartyMatchingMethodologyID, PrivTel, BusTel, Tel, PrivMobileTel & MobileTel for matching telephone numbers 
	1.7			08-11-2016		Chris Ledger		Bug fix to avoid 5 digit TitleID producing error.
	1.8			26-03-2018		Chris Ledger		14610 - Remove South Africa calculated CHECKSUM. 
													We are not using it anymore, and the existing code was matching this calculated CHECKSUM against normal NameChecksum.
	1.9			15-05-2018		Ben King			BUG 14561 - Customers not matching with capital letters within surnames											
	1.10		10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

SELECT 
	AuditItemID, 
	CountryID,
	PersonParentAuditItemID,
	AddressParentAuditItemID,
	MatchedODSAddressID,
	MatchedODSPersonID,
	EmailAddress,							--v1.5
	PrivEmailAddress,						--v1.5
	Tel,									--v1.6
	PrivTel,								--v1.6
	BusTel,								--v1.6
	MobileTel,							--v1.6
	PrivMobileTel,						--v1.6	
	VehicleIdentificationNumberUsable,
	ISNULL (CustomerIdentifier, '') AS CustomerIdentifier,
	CHECKSUM(	ISNULL(VehicleIdentificationNumber, '')	) AS VehicleChecksum,
	--CASE WHEN CountryID = (SELECT CountryID										-- V1.8
	--						FROM [$(SampleDB)].ContactMechanism.Countries 
	--						WHERE Country = 'South Africa')
	--		THEN -- South Africa to include CustomerIdentifier in Checksum
	--			BINARY_CHECKSUM( ISNULL(CONVERT (NVARCHAR(5), TitleID), N''	),		-- 1.7
	--			ISNULL(Firstname, ''),
	--			ISNULL(LastName, ''),
	--			ISNULL(SecondLastname, ''),
	--			ISNULL (CustomerIdentifier, ''))
	--		ELSE -- Everyone else does not
	--			BINARY_CHECKSUM
	--				(
	--					LEFT(COALESCE(NULLIF(FirstName, ''), NULLIF(Initials, ''),N''),(1)),
	--					REPLACE(ISNULL(LastName,N''),N' ',N'')
	--				)
	--		END AS NameChecksum,
	
	BINARY_CHECKSUM(LEFT(COALESCE(NULLIF(UPPER(FirstName),''),NULLIF(UPPER(Initials),''),N''),(1)),REPLACE(ISNULL(UPPER(LastName),N''),N' ',N'')) AS NameChecksum, --V1.9
	
	--BINARY_CHECKSUM	(
		--LEFT(COALESCE(NULLIF(FirstName, ''), NULLIF(Initials, ''),N''),(1)),	
		--REPLACE(ISNULL(LastName,N''),N' ',N'')
	--) AS NameChecksum,									-- V1.8

	LastName,
	ODSEventTypeID,							--v1.3
	PartyMatchingMethodologyID					--v1.5
FROM dbo.VWT
WHERE ISNULL(LEN(REPLACE(LastName, ' ', '')), 0) > 0

