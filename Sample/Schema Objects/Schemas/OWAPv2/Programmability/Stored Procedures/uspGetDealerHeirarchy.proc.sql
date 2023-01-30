CREATE PROCEDURE [OWAPv2].[uspGetDealerHeirarchy]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN

/*
Description
-----------
  Gets the valid dealer heirarchy values (used in the DealeDoAppointments proc)


Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			16-09-2016	Chris Ross		Created
1.1			21-09-2016	Eddie Thomas	Added in MarketID
1.2			13-10-2016	Chris Ross		13171 - Add in new SubNationalTerritory level
*/


	--Disable Counts
	SET NOCOUNT ON

	SELECT snr.SuperNationalRegion, 
			r.Region AS BusinessRegion,
			m.Market,
			nt.SubNationalTerritory,
			nr.SubNationalRegion,
			m.marketid					--v1.1
	FROM dbo.SuperNationalRegions snr 
	INNER JOIN dbo.Regions r ON r.SuperNationalRegionID = snr.SuperNationalRegionID
	INNER JOIN dbo.Markets m ON m.RegionID = r.RegionID
	INNER JOIN dbo.SubNationalTerritories nt ON nt.MarketID = m.MarketID
	INNER JOIN dbo.SubNationalRegions nr ON nr.SubNationalTerritoryID = nt.SubNationalTerritoryID
	ORDER BY  snr.SuperNationalRegion, 
			r.Region,
			m.Market,
			nt.SubNationalTerritory, 
			nr.SubNationalRegion 
			
			
	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END