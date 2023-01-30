CREATE PROCEDURE [DealerManagement].[uspAddFranchiseZones]

AS

SET NOCOUNT ON

/*

Version		Created			Author			Description	
-------		-------			------			-------			
1.0			2021-01-29		Chris Ledger	SP to Add New Zones
1.1			2021-08-18		Chris Ledger	Task 580 - Add Approved Pre-Owned FranchiseType
1.2			2021-09-19		Chris Ledger	Task 580 - Remove Approved Pre-Owned FranchiseType
*/

	-- ADD NEW AUTHORISED REPAIRER ZONES
	INSERT INTO Sample.dbo.AuthorisedRepairerZones
	(
		[AuthorisedRepairerZone], 
		[AuthorisedRepairerZoneCode], 
		[CountryID]
	)
	SELECT FL.AuthorisedRepairerZone,
		FL.AuthorisedRepairerZoneCode,
		FL.IP_CountryID AS CountryID
	FROM DealerManagement.Franchises_Load FL
		LEFT JOIN dbo.AuthorisedRepairerZones AZ ON FL.IP_CountryID = AZ.CountryID
													AND FL.AuthorisedRepairerZone = AZ.AuthorisedRepairerZone
													AND FL.AuthorisedRepairerZoneCode = AZ.AuthorisedRepairerZoneCode
	WHERE FL.IP_CountryID IS NOT NULL
		AND LEN(FL.AuthorisedRepairerZone) > 0
		AND LEN(FL.AuthorisedRepairerZoneCode) > 0
		AND FL.FranchiseType IN ('Authorised Repairer','Full Retailer')
		AND AZ.CountryID IS NULL
	GROUP BY FL.IP_CountryID, FL.AuthorisedRepairerZone, FL.AuthorisedRepairerZoneCode, AZ.AuthorisedRepairerZoneID, AZ.CountryID
	ORDER BY FL.IP_CountryID, FL.AuthorisedRepairerZone, FL.AuthorisedRepairerZoneCode


	-- ADD SALES ZONES
	INSERT INTO Sample.dbo.SalesZones
	(
		[SalesZone], 
		[SalesZoneCode], 
		[CountryID]
	)
	SELECT FL.SalesZone,
		FL.SalesZoneCode,
		FL.IP_CountryID AS CountryID
	FROM DealerManagement.Franchises_Load FL
		LEFT JOIN dbo.SalesZones SZ ON FL.IP_CountryID = SZ.CountryID
												AND FL.SalesZone = SZ.SalesZone
												AND FL.SalesZoneCode = SZ.SalesZoneCode
	WHERE FL.IP_CountryID IS NOT NULL
		AND LEN(FL.SalesZone) > 0
		AND LEN(FL.SalesZoneCode) > 0
		AND FL.FranchiseType IN ('Boutique','Full Retailer','Sales Retailer','Satellite Sales Retailer')		-- V1.1	-- V1.2
		AND SZ.CountryID IS NULL
	GROUP BY FL.IP_CountryID, FL.SalesZone, FL.SalesZoneCode, SZ.SalesZoneID, SZ.CountryID
	ORDER BY FL.IP_CountryID, FL.SalesZone, FL.SalesZoneCode


	-- ADD BODYSHOP ZONES
	INSERT INTO Sample.dbo.BodyshopZones
	(
		[BodyshopZone], 
		[BodyshopZoneCode], 
		[CountryID]
	)
	SELECT FL.BodyshopZone,
		FL.BodyshopZoneCode,
		FL.IP_CountryID AS CountryID
	FROM DealerManagement.Franchises_Load FL
		LEFT JOIN dbo.BodyshopZones BZ ON FL.IP_CountryID = BZ.CountryID
													AND FL.BodyshopZone = BZ.BodyshopZone
													AND FL.BodyshopZoneCode = BZ.BodyshopZoneCode
	WHERE FL.FranchiseCountry = 'UK'
		AND LEN(FL.BodyshopZone) > 0
		AND LEN(FL.BodyshopZoneCode) > 0
		AND FL.FranchiseType IN ('Authorised Bodyshop')
		AND BZ.CountryID IS NULL
	GROUP BY FL.IP_CountryID, FL.BodyshopZone, FL.BodyshopZoneCode, BZ.BodyshopZoneID, BZ.CountryID
	ORDER BY FL.IP_CountryID, FL.BodyshopZone, FL.BodyshopZoneCode

GO