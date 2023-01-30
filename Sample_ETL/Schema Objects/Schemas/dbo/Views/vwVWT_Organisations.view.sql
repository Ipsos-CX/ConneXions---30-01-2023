CREATE VIEW [dbo].[vwVWT_Organisations]
AS


/*
	Purpose:	List all Organisations records currently in the VWT with checksums to identify similar addresses
				and Organisations for use with deduping and matching routines.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwVWT_People
	1.1				10/07/2012		Chris Ross			Added in Unique identifier into checksum for de-dupe of South 
														African customers.
	1.2				23/07/2012		Chris Ross			Added in customerIdentifier field for the de-dupe proc.														
	1.3				02/12/2014		Chris Ross			BUG 11025 - Add in PartyMatchingMethodologyID, EmailAddress and PrivEmailAddress column.
	1.4				13/06/2016		Eddie Thomas		BUG 12449 - Add in PartyMatchingMethodologyID, PrivTel, BusTel, Tel, PrivMobileTel & MobileTel for matching telephone numbers 

*/

SELECT     
	AuditItemID,
	CountryID,
	OrganisationName,
	OrganisationParentAuditItemID,
	AddressParentAuditItemID,
	MatchedODSAddressID,
	MatchedODSOrganisationID,
	EmailAddress,							--v1.3
	PrivEmailAddress,						--v1.3
	Tel,									--v1.4
	PrivTel,								--v1.4
	BusTel,									--v1.4
	MobileTel,								--v1.4
	PrivMobileTel,							--v1.4	
	VehicleIdentificationNumberUsable,
	ISNULL (CustomerIdentifier, '') AS CustomerIdentifier,	
	CHECKSUM(ISNULL(VehicleIdentificationNumber, '')) AS VehicleChecksum,
		CASE WHEN CountryID = (select CountryID 
							from [$(SampleDB)].ContactMechanism.Countries 
							where Country = 'South Africa')
			THEN -- South Africa to include CustomerIdentifier in Checksum
				CHECKSUM(ISNULL(OrganisationName, ''),
						 ISNULL (CustomerIdentifier, '')) 
			ELSE -- Everyone else does not
				CHECKSUM(ISNULL(OrganisationName, '')) 
			END AS OrganisationNameChecksum,
	PartyMatchingMethodologyID								--v1.3
FROM dbo.VWT
WHERE (ISNULL(LEN(REPLACE(OrganisationName, ' ', '')), 0) > 0);















